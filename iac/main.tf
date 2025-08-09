terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.100"
    }
  }
}

# Configure the AWS provider
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
  cidr_block         = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "TechInnovators-VPC" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "TechInnovators-IGW" }
}

resource "aws_subnet" "public" {
  vpc_id              = aws_vpc.main.id
  cidr_block          = "10.0.1.0/24"
  availability_zone   = "us-east-1a"
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

#___________________________________________
#NACL
#------------------------------------------

# Network ACL and rules
resource "aws_network_acl" "public_acl" {
  vpc_id = aws_vpc.main.id
  subnet_ids = [aws_subnet.public.id]
  tags = {
    Name = "TechInnovators-PublicNACL"
  }
}

# Inbound ephemeral ports rule (manual change #2)
resource "aws_network_acl_rule" "public_inbound_ephemeral" {
  network_acl_id = aws_network_acl.public_acl.id
  rule_number    = 90
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Inbound rules for HTTP, HTTPS, SSH
resource "aws_network_acl_rule" "public_inbound_web" {
  network_acl_id = aws_network_acl.public_acl.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "public_inbound_ssh" {
  network_acl_id = aws_network_acl.public_acl.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}

# Outbound rules
resource "aws_network_acl_rule" "public_outbound" {
  network_acl_id = aws_network_acl.public_acl.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}


# ----------------------------------------------------
# Security Groups
# ----------------------------------------------------

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

# ----------------------------------------------------
# S3 Bucket
# ----------------------------------------------------

resource "aws_s3_bucket" "blog_app_bucket" {
  bucket = "techinnovators-blog-app-${random_pet.bucket_name.id}"
  tags = {
    Name = "TechInnovators-BlogAppBucket"
  }
}

# For creating a unique S3 bucket name
resource "random_pet" "bucket_name" {
  length = 2
}

# S3 Bucket configuration is updated to enforce encryption and block public access.
resource "aws_s3_bucket_server_side_encryption_configuration" "blog_app_bucket" {
  bucket = aws_s3_bucket.blog_app_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256" # Enabled server-side encryption with AES-256.
    }
  }
}

resource "aws_s3_bucket_policy" "blog_app_bucket_policy" {
  bucket = aws_s3_bucket.blog_app_bucket.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AWSConfigBucketPermissionsCheck",
        Effect    = "Allow",
        Principal = {
          Service = "config.amazonaws.com"
        },
        Action    = "s3:GetBucketAcl",
        Resource  = aws_s3_bucket.blog_app_bucket.arn
      },
      {
        Sid       = "AWSConfigBucketDelivery",
        Effect    = "Allow",
        Principal = {
          Service = "config.amazonaws.com"
        },
        Action    = "s3:PutObject",
        Resource  = "${aws_s3_bucket.blog_app_bucket.arn}/AWSConfig/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket                  = aws_s3_bucket.blog_app_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true # Blocked all public access.
}

# ----------------------------------------------------
# RDS PostgreSQL Database
# ----------------------------------------------------

resource "aws_db_subnet_group" "main" {
  name       = "techinnovators-db-subnet-group"
  subnet_ids = [aws_subnet.private_az1.id, aws_subnet.private_az2.id]
  tags = { Name = "TechInnovators-DB-SubnetGroup" }
}

resource "aws_db_instance" "postgresql_db" {
  allocated_storage      = 20                     # Minimal storage (GB)
  storage_type           = "gp2"                  # General Purpose SSD
  engine                 = "postgres"
  engine_version         = "17.4"                 # Recommended PostgreSQL version
  instance_class         = "db.t3.micro"          # Smallest instance type for cost-saving
  db_name                = "blogdb"               # Database name
  username               = "adminuser"            # Master username
  password               = "adminpassword"        # Master password (!!! FOR COLLEGE PROJECT ONLY. CHANGE IN PRODUCTION !!!)
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name = aws_db_subnet_group.main.name
  skip_final_snapshot    = true                   # Skip final snapshot on deletion for quicker cleanup
  publicly_accessible    = false                  # RDS should never be publicly accessible
  storage_encrypted      = true                   # ADDED: Ensure data at rest is encrypted
  performance_insights_enabled = true            # ADDED: Enable performance insights
  apply_immediately      = true                   # ADDED: Apply minor version upgrades immediately
  copy_tags_to_snapshot  = true                   # ADDED: Copy tags to snapshots
  tags = {
    Name = "TechInnovators-PostgreSQL-DB"
  }
}

resource "aws_instance" "web_server" {
  ami                 = "ami-05ffe3c48a9991133"
  instance_type       = "t3.micro"
  key_name            = "capstone"
  subnet_id           = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true
  monitoring          = true

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

    sudo yum update -y
    sudo yum install -y git docker python3-pip nc
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker ec2-user

    REPO_DIR="/home/ec2-user/TECHINNOVATORS"
    sudo mkdir -p "$REPO_DIR"
    sudo chown ec2-user:ec2-user "$REPO_DIR"
    sudo git clone --branch development https://github.com/Sheridan-College-FAST-CloudSecurity/TECHINNOVATORS.git "$REPO_DIR"
    cd "$REPO_DIR"
    echo "Building Docker image..."
    sudo docker build -t techinnovators-app .

    RDS_ENDPOINT="${aws_db_instance.postgresql_db.address}"
    RDS_PORT="${aws_db_instance.postgresql_db.port}"
    RDS_DB_NAME="${aws_db_instance.postgresql_db.db_name}"
    RDS_USERNAME="${aws_db_instance.postgresql_db.username}"
    RDS_PASSWORD="${aws_db_instance.postgresql_db.password}"

    SQLALCHEMY_URL="postgresql://$${RDS_USERNAME}:$${RDS_PASSWORD}@$${RDS_ENDPOINT}:$${RDS_PORT}/$${RDS_DB_NAME}"
    echo "Waiting for RDS to be ready..."
    until nc -zv $${RDS_ENDPOINT} $${RDS_PORT}; do
      echo "Waiting for RDS at $${RDS_ENDPOINT}..."
      sleep 5
    done
    echo "✅ RDS is reachable."

    # 💡 NEW: Ensure old container is removed before creating a new one
    echo "Checking for existing Docker container..."
    sudo docker rm -f blog-app 2>/dev/null || true

    sudo docker run -d \
      --name blog-app \
      --memory="512m" \
      --restart=always \
      -p 80:8000 \
      -e "SQLALCHEMY_DATABASE_URL=$${SQLALCHEMY_URL}" \
      -e "SECRET_KEY=your-super-secret-key" \
      techinnovators-app \
      gunicorn -k uvicorn.workers.UvicornWorker backend.main:app --bind 0.0.0.0:8000 -w 2

    echo "--- Deployment complete ---"
  EOF
}

# ----------------------------------------------------
# AWS Config & SRE Resources
# ----------------------------------------------------

# IMPORTANT: You can't create IAM roles in AWS Academy, you must use the pre-created "LabRole"
# This data source retrieves the ARN for the LabRole.
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

resource "aws_config_configuration_recorder" "default" {
  name     = "default"
  role_arn = data.aws_iam_role.lab_role.arn
}

#resource "aws_config_delivery_channel" "default" {
#  s3_bucket_name = aws_s3_bucket.blog_app_bucket.id
#}

resource "aws_config_config_rule" "s3_public_read_prohibited" {
  name = "s3-bucket-public-read-prohibited"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }
}

resource "aws_config_config_rule" "restricted_ssh" {
  name = "restricted-ssh-access"
  source {
    owner             = "AWS"
    source_identifier = "EC2_INSTANCE_NO_PUBLIC_IP"
  }
}

resource "aws_sns_topic" "alerts" {
  name = "TechInnovators-Alerts"
}

resource "aws_cloudwatch_metric_alarm" "ec2_cpu_alarm" {
  alarm_name          = "High_CPU_Utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This alarm will trigger if the average CPU utilization is too high."
  alarm_actions       = [aws_sns_topic.alerts.arn]
  dimensions = {
    InstanceId = aws_instance.web_server.id
  }
}

resource "aws_cloudwatch_log_group" "blog_app_logs" {
  name            = "/ecs/blog-app-logs"
  retention_in_days = 7
}

# ----------------------------------------------------
# Outputs (for easy access to deployed info)
# ----------------------------------------------------

output "ec2_public_ip" {
  value = aws_instance.web_server.public_ip
}

output "application_url" {
  value = "http://${aws_instance.web_server.public_ip}"
}

output "rds_endpoint" {
  value = aws_db_instance.postgresql_db.address
}