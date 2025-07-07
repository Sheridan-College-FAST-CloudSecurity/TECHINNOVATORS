variable "sg_id"       { type = string }
variable "subnet_id"   { type = string }
variable "key_name"    { type = string }
variable "repo_url"    { type = string }
variable "db_endpoint" { type = string }
variable "db_user"     { type = string }
variable "db_pass"     { 
    type = string
    sensitive = true 
}
