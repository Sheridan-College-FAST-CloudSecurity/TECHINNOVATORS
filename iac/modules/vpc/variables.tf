# variables.tf (or directly in main.tf if this is your root configuration)

variable "cidr_block" {
  description = "The CIDR block for the VPC."
  type        = string
}

variable "name" {
  description = "The name tag for the VPC and its subnets."
  type        = string
}