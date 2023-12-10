resource "azurerm_lb_backend_address_pool" "backend-pool" {
  name            = var.name
  loadbalancer_id = var.load_balancer_id
}

locals {
  nic_rg   = var.nic_id == "" ? "" : split("/", var.nic_id)[4]
  nic_name = var.nic_id == "" ? "" : split("/", var.nic_id)[8]
}

data "azurerm_network_interface" "nic" {
  count               = var.nic_id == "" ? 0 : 1
  name                = local.nic_name
  resource_group_name = local.nic_rg
}

resource "azurerm_network_interface_backend_address_pool_association" "lb-backend-pool-nic-association" {
  count = var.nic_id == "" ? 0 : 1
  # Because data.azurerm_network_interface.nic has "count" set, its attributes must be accessed on specific instances
  # Hence: data.azurerm_network_interface.nic[0]
  network_interface_id    = data.azurerm_network_interface.nic[0].id
  ip_configuration_name   = data.azurerm_network_interface.nic[0].ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend-pool.id
}

resource "azurerm_lb_backend_address_pool_address" "lb-backend-pool-ip-association" {
  count                   = var.ip_address != "" && var.vnet_id != "" ? 1 : 0
  name                    = "lb-backend-pool-ip-association"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend-pool.id
  virtual_network_id      = var.vnet_id
  ip_address              = var.ip_address
}

// IaaS load balancing rule
resource "azurerm_lb_rule" "lb_rules" {
  for_each = var.lb_rules

  name            = each.key
  loadbalancer_id = var.load_balancer_id
  protocol        = each.value.protocol
  frontend_port   = each.value.frontend_port
  backend_port    = each.value.backend_port

  frontend_ip_configuration_name = var.lb_frontend_ip_configuration_name
  backend_address_pool_ids = [
    azurerm_lb_backend_address_pool.backend-pool.id
  ]
}