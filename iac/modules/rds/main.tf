resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "blogosphere-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "blogosphere-db-subnet-group"
  }
}

resource "aws_db_instance" "postgres" {
  identifier         = "blogosphere-db"
  engine             = "postgres"
  engine_version     = "15"
  instance_class     = "db.t3.micro"
  allocated_storage  = 20
  db_name            = var.db_name
  username           = var.db_username
  password           = var.db_password
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [var.security_group_id]
  skip_final_snapshot = true
  publicly_accessible = false

  tags = {
    Name = "blogosphere-db"
  }
}
