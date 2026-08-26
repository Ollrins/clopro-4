variable "service_account_key_file" {
  type    = string
  default = "/home/Ollrins/key.json"
}

variable "cloud_id" {
  type = string
}

variable "folder_id" {
  type = string
}

variable "ssh_public_key" {
  type    = string
  default = "/home/Ollrins/key.pub"
}

variable "ssh_user" {
  type    = string
  default = "Ollrins"
}

# MySQL
variable "mysql_db_name" {
  type    = string
  default = "netology_db"
}

variable "mysql_user_login" {
  type    = string
  default = "netology_user"
}

variable "mysql_user_password" {
  type      = string
  default   = "SecurePassword123!"
  sensitive = true
}
