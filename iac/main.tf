# main.tf

provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "techinnovators-tfstate-vinay"
    key    = "techinnovators/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "TechInnovators-VPC" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "TechInnovators-IGW" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = { Name = "TechInnovators-PublicSubnet" }
}

resource "aws_subnet" "private_az1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1a"
  tags = { Name = "TechInnovators-PrivateSubnet-AZ1" }
}

resource "aws_subnet" "private_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1b"
  tags = { Name = "TechInnovators-PrivateSubnet-AZ2" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "TechInnovators-PublicRouteTable" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "ec2_sg" {
  name        = "techinnovators-ec2-sg"
  description = "Allow HTTP, HTTPS, SSH inbound traffic to EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "TechInnovators-EC2-SG" }
}

resource "aws_security_group" "rds_sg" {
  name        = "techinnovators-rds-sg"
  description = "Allow PostgreSQL traffic only from EC2 instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "TechInnovators-RDS-SG" }
}

resource "aws_db_subnet_group" "main" {
  name       = "techinnovators-db-subnet-group"
  subnet_ids = [aws_subnet.private_az1.id, aws_subnet.private_az2.id]
  tags = { Name = "TechInnovators-DB-SubnetGroup" }
}

resource "aws_db_instance" "postgresql_db" {
  allocated_storage           = 20
  storage_type                = "gp2"
  engine                      = "postgres"
  engine_version              = "17.4"
  instance_class              = "db.t3.micro"
  db_name                     = "blogdb"
  username                    = "adminuser"
  password                    = "adminpassword"
  vpc_security_group_ids      = [aws_security_group.rds_sg.id]
  db_subnet_group_name        = aws_db_subnet_group.main.name
  skip_final_snapshot         = true
  publicly_accessible         = true
  storage_encrypted           = false
  performance_insights_enabled = true
  apply_immediately           = true
  copy_tags_to_snapshot       = true
  tags = { Name = "TechInnovators-PostgreSQL-DB" }
}

resource "aws_instance" "web_server" {
  ami                         = "ami-05ffe3c48a9991133"
  instance_type               = "t3.micro"
  key_name                    = "capstone"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true
  monitoring                  = true

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    encrypted = true
  }

  user_data = <<-EOF
    #!/bin/bash
    exec > /var/log/user-data.log 2>&1
    set -xe

    yum update -y
    yum install -y git docker python3-pip nc
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user

    REPO_DIR="/home/ec2-user/TECHINNOVATORS"
    git clone --branch development https://github.com/Sheridan-College-FAST-CloudSecurity/TECHINNOVATORS.git "$REPO_DIR"
    cd "$REPO_DIR"

    docker build -t techinnovators-app .

    RDS_ENDPOINT="${aws_db_instance.postgresql_db.address}"
    RDS_PORT="${aws_db_instance.postgresql_db.port}"
    RDS_DB_NAME="${aws_db_instance.postgresql_db.db_name}"
    RDS_USERNAME="${aws_db_instance.postgresql_db.username}"
    RDS_PASSWORD="${aws_db_instance.postgresql_db.password}"

    SQLALCHEMY_URL="postgresql://$${RDS_USERNAME}:$${RDS_PASSWORD}@$${RDS_ENDPOINT}:$${RDS_PORT}/$${RDS_DB_NAME}"

    until nc -zv $${RDS_ENDPOINT} $${RDS_PORT}; do
      echo "Waiting for RDS at $${RDS_ENDPOINT}..."
      sleep 5
    done

    docker run -d \
      --name blog-app \
      -p 80:8000 \
      -e "SQLALCHEMY_DATABASE_URL=$${SQLALCHEMY_URL}" \
      -e "SECRET_KEY=your-super-secret-key" \
      techinnovators-app

    echo "--- Deployment complete ---"
  EOF
}

output "ec2_public_ip" {
  value = aws_instance.web_server.public_ip
}

output "application_url" {
  value = "http://${aws_instance.web_server.public_ip}"
}

output "rds_endpoint" {
  value = aws_db_instance.postgresql_db.address
}
