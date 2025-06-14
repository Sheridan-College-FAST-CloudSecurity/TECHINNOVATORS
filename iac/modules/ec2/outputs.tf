output "instance_public_ip" {
  value = aws_instance.nginx_instance.public_ip
}

output "security_group_id" {
  value = aws_security_group.nginx_sg.id
}
