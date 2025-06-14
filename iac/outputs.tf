output "public_subnet_id" {
  value = module.public_subnet_1.subnet_id
}

output "nginx_ec2_public_ip" {
  value = module.ec2.instance_public_ip
}
