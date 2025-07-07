#output "blog_url"          { value = "http://${aws_instance.nginx.public_ip}" }
#output "db_endpoint"       { value = aws_db_instance.postgres.address }
#output "ssh_cmd"           { value = "ssh -i <path-to-pem> ec2-user@${aws_instance.nginx.public_ip}" }
