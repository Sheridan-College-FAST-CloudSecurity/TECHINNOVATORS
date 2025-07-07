variable "my_ip_cidr" { description = "Your laptop IP/CIDR, e.g. 203.0.113.4/32" }
variable "key_name"   { description = "Existing EC2 key-pair in us-east-1" }
variable "repo_url"   { description = "Git URL of Blogosphere back-end repo" }
variable "db_user"    { default     = "bloguser" }
variable "db_pass"    { sensitive   = true }
