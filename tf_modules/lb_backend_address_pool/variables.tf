variable "name" {
  type        = string
  description = "Name of the backend address pool"
}

variable "load_balancer_id" {
  type        = string
  description = "Azure ID of the load balancer where to add backend pool"
}

variable "lb_frontend_ip_configuration_name" {
  type        = string
  description = "Frontend IP confiuration name of the load balancer"
}

variable "nic_id" {
  type        = string
  default     = ""
  description = "The Azure ID of the NIC to configure as backend pool. This parameter only works for NICs associated to VMs, not for private endpoints."
}

variable "ip_address" {
  type        = string
  default     = ""
  description = "IP address of the resource to be included in backend address pool. Use this parameter for private endpoints."
}

variable "vnet_id" {
  type        = string
  default     = ""
  description = "Azure ID of VNet where backend is located. Use this parameter for private endpoints."
}

variable "lb_rules" {
  type = map(object({
    protocol      = string,
    frontend_port = number,
    backend_port  = number
  }))
  description = "Load balacing rules for that backend address pool"
}