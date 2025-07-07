variable "sg_id"      { type = string }
variable "subnet_ids" { type = list(string) }
variable "db_user"    { type = string }
variable "db_pass"    { 
    type = string
    sensitive = true 
 }
