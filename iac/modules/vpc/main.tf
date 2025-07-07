resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.name      # <- tag to satisfy SCP condition
    Project = "Blogosphere"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.cidr_block, 4, 0)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name    = "${var.name}-public-a"
    Project = "Blogosphere"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.cidr_block, 4, 1)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[1]

  tags = {
    Name    = "${var.name}-public-b"
    Project = "Blogosphere"
  }
}

output "vpc_id"      { value = aws_vpc.main.id }
output "subnet_ids"  { value = [aws_subnet.public_a.id, aws_subnet.public_b.id] }


data "aws_availability_zones" "available" {
  state = "available"
  # You can optionally filter by region if needed, but by default it uses the provider's region
}