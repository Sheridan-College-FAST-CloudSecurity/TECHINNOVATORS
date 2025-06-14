variable "subnet_ids" {
  type = list(string)
}

variable "security_group_id" {
  type = string
}

variable "db_name" {
  type    = string
  default = "blogodb"
}

variable "db_username" {
  type    = string
  default = "blogouser"
}

variable "db_password" {
  type    = string
  sensitive = true
}
