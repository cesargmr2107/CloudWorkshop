variable "location" {
  type    = string
  default = "spaincentral"
}

variable "cw-iaas-app-port" {
  type    = number
  default = 8081
}

variable "cw-paas-app-port" {
  type    = number
  default = 8082
}

variable "mssql-admin" {
  type    = string
  default = "mssql-admin"
}

variable "vm-user" {
  type = string
  default = "adminuser"
}

variable "app-github-repo" {
  type = string
  default = "https://github.com/cesargmr2107/CloudWorkshopWeb"
}