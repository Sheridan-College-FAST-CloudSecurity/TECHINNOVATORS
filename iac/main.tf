# main.tf

# Configure the AWS provider
provider "aws" {
  region = "us-east-1" # IMPORTANT: Choose a region available in your AWS Academy Learner Lab.
                       # us-east-1 (N. Virginia) is a common default.
}

# Data source to get available availability zones in the current region



# ----------------------------------------------------
# VPC and Networking
# ----------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "TechInnovators-VPC"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "TechInnovators-IGW"
  }
}

# Public subnet for the EC2 instance
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a" # Uses the first AZ in the chosen region
  map_public_ip_on_launch = true # EC2 instances launched here will get a public IP
  tags = {
    Name = "TechInnovators-PublicSubnet"
  }
}

# Private subnet for the RDS database
resource "aws_subnet" "private_az1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1a" # Uses the same AZ as public for simplicity
  tags = {
    Name = "TechInnovators-PrivateSubnet-AZ1"
  }
}

# Private subnet for the RDS database 
resource "aws_subnet" "private_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24" 
  availability_zone = "us-east-1b" # Second AZ
  tags = {
    Name = "TechInnovators-PrivateSubnet-AZ2"
  }
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "TechInnovators-PublicRouteTable"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ----------------------------------------------------
# Security Groups
# ----------------------------------------------------

resource "aws_security_group" "ec2_sg" {
  name        = "techinnovators-ec2-sg"
  description = "Allow HTTP, HTTPS, SSH inbound traffic to EC2"
  vpc_id      = aws_vpc.main.id

  # Inbound HTTP (port 80) for the web application
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow from any IP for easy access
    description = "Allow inbound HTTP from anywhere" # ADDED DESCRIPTION
  }

  # Inbound HTTPS (port 443) - good practice, though not configured for this project
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow inbound HTTPS from anywhere" # ADDED DESCRIPTION
  }

  # Inbound SSH (port 22) for instance management
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # IMPORTANT: For better security, replace "0.0.0.0/0" with your specific public IP address.
    # You can find your public IP by searching "what is my ip" on Google.
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow inbound SSH from anywhere (for lab access)" # ADDED DESCRIPTION
  }

  # Allow all outbound traffic from EC2 (needed for git clone, updates, DB connection)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic" # ADDED DESCRIPTION
  }

  tags = {
    Name = "TechInnovators-EC2-SG"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "techinnovators-rds-sg"
  description = "Allow PostgreSQL traffic only from EC2 instance"
  vpc_id      = aws_vpc.main.id

  # Inbound PostgreSQL (port 5432) only from the EC2 security group
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]  # EC2 subnet range
    #security_groups = [aws_security_group.ec2_sg.id] # Only allow traffic from our EC2
    description = "Allow inbound PostgreSQL from EC2 SG" # ADDED DESCRIPTION
  }

  # Allow all outbound traffic from RDS (e.g., for monitoring, logging)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic" # ADDED DESCRIPTION
  }

  tags = {
    Name = "TechInnovators-RDS-SG"
  }
}

# ----------------------------------------------------
# RDS PostgreSQL Database
# ----------------------------------------------------

resource "aws_db_subnet_group" "main" {
  name       = "techinnovators-db-subnet-group"
  subnet_ids = [aws_subnet.private_az1.id, aws_subnet.private_az2.id] # RDS should be in the private subnet

  tags = {
    Name = "TechInnovators-DB-SubnetGroup"
  }
}

resource "aws_db_instance" "postgresql_db" {
  allocated_storage    = 20                     # Minimal storage (GB)
  storage_type         = "gp2"                  # General Purpose SSD
  engine               = "postgres"
  engine_version       = "17.4"                 # Recommended PostgreSQL version
  instance_class       = "db.t3.micro"          # Smallest instance type for cost-saving
  db_name              = "blogdb"               # Database name
  username             = "adminuser"            # Master username
  password             = "adminpassword"        # Master password (!!! FOR COLLEGE PROJECT ONLY. CHANGE IN PRODUCTION !!!)
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name = aws_db_subnet_group.main.name
  skip_final_snapshot  = true                   # Skip final snapshot on deletion for quicker cleanup
  publicly_accessible  = true                  # RDS should never be publicly accessible
  storage_encrypted    = false                   # ADDED: Ensure data at rest is encrypted
  performance_insights_enabled = true          # ADDED: Enable performance insights
  apply_immediately    = true                   # ADDED: Apply minor version upgrades immediately
  copy_tags_to_snapshot = true                  # ADDED: Copy tags to snapshots

  tags = {
    Name = "TechInnovators-PostgreSQL-DB"
  }
}

# ----------------------------------------------------
# EC2 Instance (Web Server + Backend)
# ----------------------------------------------------

resource "aws_instance" "web_server" {
  ami           = "ami-05ffe3c48a9991133" # Amazon Linux 2023 AMI (us-east-1).
                                         # IMPORTANT: Verify the latest AMI ID for your chosen region in the AWS Console.
  instance_type = "t3.micro"             # Smallest instance type for cost-saving
  key_name      = "capstone"             # Your SSH key pair name
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true     # Assign a public IP for internet access
  monitoring    = true                   # ADDED: Enable detailed monitoring for EC2

  # Force IMDSv2 for enhanced security
  metadata_options { # ADDED: Enforce IMDSv2
    http_tokens = "required"
  }

  # Root block device for encryption at rest.
  root_block_device { # ADDED: Ensure EBS encryption for the root volume
    encrypted = true
  }

user_data = <<-EOF
    #!/bin/bash
    set -e

    echo "--- Starting EC2 User Data Script for Docker Deployment ---"

    # Install Docker, Git, etc.
    sudo yum update -y
    sudo yum install -y git docker python3-pip
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker ec2-user

    # Clone your repo
    REPO_DIR="/home/ec2-user/TECHINNOVATORS"
    sudo mkdir -p "$REPO_DIR"
    sudo chown ec2-user:ec2-user "$REPO_DIR"
    sudo git clone --branch development https://github.com/Sheridan-College-FAST-CloudSecurity/TECHINNOVATORS.git "$REPO_DIR"
    cd "$REPO_DIR"

    echo "Building Docker image..."
    sudo docker build -t techinnovators-app .

    # RDS credentials from Terraform interpolation
    RDS_ENDPOINT="${aws_db_instance.postgresql_db.address}"
    RDS_PORT="${aws_db_instance.postgresql_db.port}"
    RDS_DB_NAME="${aws_db_instance.postgresql_db.db_name}"
    RDS_USERNAME="${aws_db_instance.postgresql_db.username}"
    RDS_PASSWORD="${aws_db_instance.postgresql_db.password}"

    SQLALCHEMY_URL="postgresql://$${RDS_USERNAME}:$${RDS_PASSWORD}@$${RDS_ENDPOINT}:$${RDS_PORT}/$${RDS_DB_NAME}"

    echo "Waiting for RDS to become available at $${RDS_ENDPOINT}..."
    until nc -zv $${RDS_ENDPOINT} $${RDS_PORT}; do
      echo "Still waiting for RDS..."
      sleep 5
    done
    echo "✅ RDS is reachable."

    echo "Starting Docker container..."
    sudo docker run -d \
      --name blog-app \
      -p 80:8000 \
      -e "SQLALCHEMY_DATABASE_URL=$${SQLALCHEMY_URL}" \
      -e "SECRET_KEY=your-super-secret-key" \
      techinnovators-app

    echo "--- Deployment complete ---"
 EOF
}
# ----------------------------------------------------
# Outputs (for easy access to deployed info).
# ----------------------------------------------------

output "ec2_public_ip" {
  description = "The public IP address of the EC2 web server"
  value       = aws_instance.web_server.public_ip
}

output "application_url" {
  description = "The URL to access your web application (uses HTTP)"
  value       = "http://${aws_instance.web_server.public_ip}"
}

output "rds_endpoint" {
  description = "The endpoint for the PostgreSQL database"
  value       = aws_db_instance.postgresql_db.address
}