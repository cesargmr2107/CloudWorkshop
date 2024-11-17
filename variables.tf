#####################################################################################
#                                                                                   #
#   COMMON VARIABLES                                                                #
#                                                                                   #
#####################################################################################

variable "common_name_prefix" {
  type        = string
  default     = "cw-common"
  description = "Name prefix for all common resources."
}

variable "common_terraform_backend_name" {
  type        = string
  default     = "cwterraformbackend"
  description = "The name of the storage account that holds the terraform backend."
}

variable "common_terraform_backend_rg" {
  type        = string
  default     = "cw-common-rg"
  description = "The name of the resource group of the storage account that holds the terraform backend."
}

variable "common_location" {
  type        = string
  default     = "spaincentral"
  description = "The Azure region where the resources will be deployed."
}

variable "common_app_github_repo" {
  type        = string
  default     = "https://github.com/cesargmr2107/CloudWorkshopWeb"
  description = "The URL of the GitHub repository containing the application source code."
}

variable "common_vnet_range" {
  type        = string
  default     = "10.0.0.0/20"
  description = "The CIDR block for the virtual network."
}

variable "common_subnet_list" {
  type        = list(string)
  default     = [
    "cw-common-gateway-subnet",
    "cw-iaas-web-app-subnet",
    "cw-paas-web-app-pe-subnet",
    "cw-paas-web-app-int-subnet",
    "cw-db-subnet"
  ]
  description = "A list of names for the subnets to be created in the virtual network."
}

variable "common_subnet_newbits" {
  type        = number
  default     = 4
  description = "The number of bits to add to the base CIDR prefix for calculating subnet ranges."
}

#####################################################################################
#                                                                                   #
#   IAAS APP VARIABLES                                                              #
#                                                                                   #
#####################################################################################

variable "iaas_app_name_prefix" {
  type        = string
  default     = "cw-iaas-app"
  description = "Name prefix for all IaaS application resources."
}

variable "iaas_app_request_routing_rule_priority" {
  type        = number
  default     = 10
  description = "The priority of the request routing rule for the IaaS application."
}

variable "iaas_app_frontend_port" {
  type        = number
  default     = 8081
  description = "The frontend port for the IaaS application."
}

variable "iaas_app_frontend_protocol" {
  type        = string
  default     = "Http"
  description = "The frontend protocol for the IaaS application."
}

variable "iaas_app_backend_port" {
  type        = number
  default     = 80
  description = "The backend port for the IaaS application."
}

variable "iaas_app_backend_protocol" {
  type        = string
  default     = "Http"
  description = "The backend protocol for the IaaS application."
}

variable "iaas_app_vm_admin" {
  type        = string
  default     = "vm-admin"
  description = "The username for the administrator of the IaaS virtual machine."
}

variable "iaas_app_vm_secret" {
  type        = string
  default     = "vm-secret"
  description = "The name of the secret stored on Key vault for the VM admin."
}

#####################################################################################
#                                                                                   #
#   PAAS APP VARIABLES                                                              #
#                                                                                   #
#####################################################################################

variable "paas_app_name_prefix" {
  type        = string
  default     = "cw-paas-app"
  description = "Name prefix for all PaaS application resources."
}

variable "paas_app_request_routing_rule_priority" {
  type        = number
  default     = 20
  description = "The priority of the request routing rule for the PaaS application."
}

variable "paas_app_frontend_port" {
  type        = number
  default     = 8082
  description = "The frontend port for the PaaS application."
}

variable "paas_app_frontend_protocol" {
  type        = string
  default     = "Http"
  description = "The frontend protocol for the PaaS application."
}

variable "paas_app_backend_port" {
  type        = number
  default     = 443
  description = "The backend port for the PaaS application."
}

variable "paas_app_backend_protocol" {
  type        = string
  default     = "Https"
  description = "The backend protocol for the PaaS application."
}

variable "paas_app_source_control_token" {
  type        = string
  default     = "github-token"
  description = "The name of the secret stored on Key vault for the PAT GitHub token used for CI/CD to the PaaS application."
}

#####################################################################################
#                                                                                   #
#   DB APP VARIABLES                                                                #
#                                                                                   #
#####################################################################################

variable "data_name_prefix" {
  type        = string
  default     = "cw-data"
  description = "Name prefix for all data resources."
}

variable "data_db_admin" {
  type        = string
  default     = "db-admin"
  description = "The administrator username for the database."
}

variable "data_db_secret" {
  type        = string
  default     = "db-secret"
  description = "The name of the secret stored on Key vault for the DB admin."
}

variable "data_db_setup_bacpac_path" {
  type        = string
  default     = "mssql-setup/db_setup.bacpac"
  description = "The path of the initial setup bacpac file on the Terraform Storage Account for the MSSQL DB."
}