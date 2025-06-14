variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the subnet"
  type        = string
}

variable "az" {
  description = "Availability Zone"
  type        = string
}

variable "name" {
  description = "Subnet name"
  type        = string
}
