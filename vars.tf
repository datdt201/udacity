variable "prefix" {
  description = "The prefix which should be used for all resources in this project"
  default = "terraform"
}

variable "resource_group_name" {
  description = "The Azure Resource Group in which all resources in this project should be created."
  default = "Azuredevops"
}

variable "application_port" {
  description = "The port that web server run on"
  default = 80
}

variable "server_count" {
  description = "The number of web servers"
  default = 2
}

variable "username" {
  description = "The user name to SSH into virtual machine"
  default = "azureuser"
}

variable "password" {
  description = "The password to SSH into virtual machine"
  default = "Password@1234"
}