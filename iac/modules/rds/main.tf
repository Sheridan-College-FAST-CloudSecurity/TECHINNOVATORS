resource "aws_db_subnet_group" "db_subnet_group" {
  name_prefix = "blogosphere-db-subnet-"
  subnet_ids  = var.subnet_ids

  lifecycle { create_before_destroy = true }

  tags = { Name = "blogosphere-db-subnet" }
}

resource "aws_db_instance" "postgres" {
  identifier              = "blogosphere-db"
  engine                  = "postgres"
  engine_version          = "15"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  username                = var.db_user
  password                = var.db_pass
  db_name                 = "blogodb"

  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids  = [var.sg_id]

  publicly_accessible     = true           # no NAT needed
  deletion_protection     = false          # allow destroy
  skip_final_snapshot     = true           # dev only

  tags = { Name = "blogosphere-db" }
}

output "endpoint" { value = aws_db_instance.postgres.endpoint }
