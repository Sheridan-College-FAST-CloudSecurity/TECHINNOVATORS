resource "aws_instance" "app" {
  ami           = "ami-0c02fb55956c7d316"   # Amazon Linux 2
  instance_type = "t2.micro"
  subnet_id     = var.subnet_id
  vpc_security_group_ids = [var.sg_id]
  key_name      = var.key_name

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y git python3-pip
    cd /home/ec2-user
    git clone ${var.repo_url} app
    cd app
    pip3 install -r requirements.txt
    echo "DB_HOST=${var.db_endpoint}"   >> /etc/environment
    echo "DB_USER=${var.db_user}"       >> /etc/environment
    echo "DB_PASS=${var.db_pass}"       >> /etc/environment
    nohup uvicorn main:app --host 0.0.0.0 --port 8000 &
  EOF

  tags = { Name = "blogosphere-ec2" }
}

output "public_ip" { value = aws_instance.app.public_ip }
