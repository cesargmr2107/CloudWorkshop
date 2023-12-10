
variable "location" {
  type        = string
  description = "Location where to create the private endpoint"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group where to create the private endpoint"
}

variable "private_link_enabled_resource_name" {
  type        = string
  description = "The name of the resource to which the private endpoint will be added"
}

variable "private_link_enabled_resource_id" {
  type        = string
  description = "The Azure ID of the resource to which the private endpoint will be added"
}

variable "subnet_id" {
  type        = string
  description = "The Azure ID of the subnet where to deploy the private endpoint"
}

variable "subresource_names" {
  type        = list(string)
  description = "Subresources to protect via private endpoint"
}

variable "private_dns_zone_id" {
  type        = string
  description = "Azure ID of the Private DNS zone where to add A record"
}