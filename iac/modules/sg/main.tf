resource "aws_security_group" "blogosphere" {
  name        = "blogosphere-sg"
  description = "HTTP, SSH (my IP), Postgres internal"
  vpc_id      = var.vpc_id

  # SSH only from your workstation
  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  # HTTP for the app
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # PostgreSQL — allow EC2 <-> RDS within the SG
  ingress {
    description = "Postgres 5432 self"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "blogosphere-sg" }
}

output "sg_id" { value = aws_security_group.blogosphere.id }
