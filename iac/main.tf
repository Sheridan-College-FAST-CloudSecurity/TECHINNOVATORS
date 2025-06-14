provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source     = "./modules/vpc"
  cidr_block = "10.0.0.0/16"
  name       = "blogosphere-vpc"
}

module "public_subnet_1" {
  source     = "./modules/subnet"
  vpc_id     = module.vpc.vpc_id
  cidr_block = "10.0.1.0/24"
  az         = "us-east-1a"
  name       = "public-subnet-1"
}

module "public_subnet_2" {
  source     = "./modules/subnet"
  vpc_id     = module.vpc.vpc_id
  cidr_block = "10.0.2.0/24"
  az         = "us-east-1b"
  name       = "public-subnet-2"
}

module "ec2" {
  source     = "./modules/ec2"
  vpc_id     = module.vpc.vpc_id
  subnet_id  = module.public_subnet_1.subnet_id
  key_name   = "capstone" # Ensure this key pair exists in your AWS Academy EC2
}


resource "aws_internet_gateway" "igw" {
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "blogosphere-igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "blogosphere-public-rt"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "subnet_1_assoc" {
  subnet_id      = module.public_subnet_1.subnet_id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "subnet_2_assoc" {
  subnet_id      = module.public_subnet_2.subnet_id
  route_table_id = aws_route_table.public_rt.id
}

module "rds" {
  source             = "./modules/rds"
  subnet_ids         = [module.public_subnet_1.subnet_id, module.public_subnet_2.subnet_id]
  security_group_id  = module.ec2.security_group_id
  db_name            = "blogodb"
  db_username        = "blogouser"
  db_password        = "BlogoSecurePass123"
}
