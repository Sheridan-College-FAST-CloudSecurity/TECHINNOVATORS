variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "Public Subnet ID"
  type        = string
}

variable "key_name" {
  description = "EC2 Key Pair name"
  type        = string
}
