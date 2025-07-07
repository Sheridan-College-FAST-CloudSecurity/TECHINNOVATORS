resource "aws_db_subnet_group" "db_subnet_group" {
  name_prefix = "blogosphere-db-subnet-"
  subnet_ids  = var.subnet_ids

  lifecycle { create_before_destroy = true }

  tags = { Name = "blogosphere-db-subnet" }
}

resource "aws_db_instance" "postgres" {
  identifier        = "blogosphere-db"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  username          = var.db_user
  password          = var.db_pass
  db_name           = "blogodb"
  storage_encrypted = true            # ✔ CKV_AWS_16

  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [var.sg_id]

  publicly_accessible                 = false # no NAT needed
  iam_database_authentication_enabled = true  # ✔ CKV_AWS_161 ★
  auto_minor_version_upgrade          = true  # ✔ CKV_AWS_226 ★
  multi_az                            = false # justify skip (see .checkov.yaml)
  # Monitoring & insights
  monitoring_interval          = 60    # ✔ CKV_AWS_118 ★
  performance_insights_enabled = true  # ✔ CKV_AWS_353 ★
  deletion_protection          = false # allow destroy
  skip_final_snapshot          = true  # dev only

  tags = { Name = "blogosphere-db" }
}

output "endpoint" { value = aws_db_instance.postgres.endpoint }
