# Terraform & Provider
#####################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

#####################
# ❶ Networking
#####################
module "vpc" {
  source     = "./modules/vpc"
  cidr_block = "10.0.0.0/16"
  name       = "blogosphere-vpc"
}

#####################
#  ⚡ NEW – Public routing
#####################

# 1. Internet-gateway for the VPC
resource "aws_internet_gateway" "gw" {
  vpc_id = module.vpc.vpc_id
  tags   = { Name = "blogosphere-igw" }
}

# 2. Route-table that sends 0.0.0.0/0 → IGW
resource "aws_route_table" "public_rt" {
  vpc_id = module.vpc.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = { Name = "blogosphere-public-rt" }
}

# 3. Associate *each* public subnet with that route-table
resource "aws_route_table_association" "subnet_1_assoc" {
  subnet_id      = module.vpc.subnet_ids[0]
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "subnet_2_assoc" {
  subnet_id      = module.vpc.subnet_ids[1]
  route_table_id = aws_route_table.public_rt.id
}

module "sg" {
  source     = "./modules/sg"
  vpc_id     = module.vpc.vpc_id
  my_ip_cidr = var.my_ip_cidr
}

#####################
# ❷ Data tier (RDS)
#####################
module "rds" {
  source     = "./modules/rds"
  sg_id      = module.sg.sg_id
  subnet_ids = module.vpc.subnet_ids
  db_user    = var.db_user
  db_pass    = var.db_pass
  depends_on = [
    aws_internet_gateway.gw,
    aws_route_table_association.subnet_1_assoc,
    aws_route_table_association.subnet_2_assoc
  ]
}

#####################
# ❸ Compute tier (EC2 + app)
#####################
module "ec2" {
  source      = "./modules/ec2"
  sg_id       = module.sg.sg_id
  subnet_id   = module.vpc.subnet_ids[0] # put EC2 in first public subnet
  key_name    = var.key_name
  repo_url    = var.repo_url
  db_endpoint = module.rds.endpoint
  db_user     = var.db_user
  db_pass     = var.db_pass
}

#####################
# Outputs
#####################
output "app_url" {
  value = "http://${module.ec2.public_ip}"
}

output "db_endpoint" {
  value = module.rds.endpoint
}
