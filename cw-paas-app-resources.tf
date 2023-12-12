resource "azurerm_resource_group" "cw-paas-app-rg" {
  name     = "cw-paas-app-rg"
  location = "westeurope"
}

resource "azurerm_service_plan" "cw-paas-app-asp" {
  name                = "cw-paas-app-asp"
  resource_group_name = azurerm_resource_group.cw-paas-app-rg.name
  location            = azurerm_resource_group.cw-paas-app-rg.location
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "cw-paas-app-asw" {

  # Basic info
  name                = "cw-paas-app-asw"
  resource_group_name = azurerm_resource_group.cw-paas-app-rg.name
  location            = azurerm_resource_group.cw-paas-app-rg.location
  service_plan_id     = azurerm_service_plan.cw-paas-app-asp.id

  # Settings

  https_only = true

  site_config {
    minimum_tls_version = "1.2"
  }

  identity {
    type = "SystemAssigned"
  }

}

resource "azurerm_app_service_source_control" "cw-paas-app-source-control" {
  app_id             = azurerm_linux_web_app.cw-paas-app-asw.id
  repo_url           = "https://github.com/cesargmr2107/CloudWorkshop/tree/main/www"
  branch             = "main"
  use_manual_integration = true
  use_mercurial      = false
}

# PRIVATE NETWORKING 

resource "azurerm_private_dns_zone" "cw-paas-app-asw-dns-zone" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.cw-paas-app-rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "cw-paas-app-asw-dns-zone-link" {
  name                  = "cw-paas-app-asw-dns-zone-link"
  resource_group_name   = azurerm_resource_group.cw-paas-app-rg.name
  private_dns_zone_name = azurerm_private_dns_zone.cw-paas-app-asw-dns-zone.name
  virtual_network_id    = azurerm_virtual_network.cw-common-vnet.id
}

module "cw-paas-app-asw-endpoint" {
  source                             = "./tf_modules/private_endpoint"
  location                           = azurerm_resource_group.cw-paas-app-rg.location
  resource_group_name                = azurerm_resource_group.cw-paas-app-rg.name
  private_link_enabled_resource_name = azurerm_linux_web_app.cw-paas-app-asw.name
  private_link_enabled_resource_id   = azurerm_linux_web_app.cw-paas-app-asw.id
  subnet_id                          = azurerm_subnet.cw-subnets["cw-paas-web-app-frontend-pe"].id
  subresource_names                  = ["sites"]
  private_dns_zone_id                = azurerm_private_dns_zone.cw-paas-app-asw-dns-zone.id
}

# LOAD BALANCER BACKEND POOL

# module "lb-paas-backend-pool" {
#   # Module source
#   source = "./tf_modules/lb_backend_address_pool"
# 
#   # Context input
#   name                              = "lb-paas-backend-pool"
#   load_balancer_id                  = azurerm_lb.cw-common-lb.id
#   lb_frontend_ip_configuration_name = azurerm_lb.cw-common-lb.frontend_ip_configuration[0].name
#   ip_address                        = module.cw-paas-app-asw-endpoint.ip_address
#   vnet_id                           = azurerm_virtual_network.cw-common-vnet.id
# 
#   # Load balancing rules
#   lb_rules = {
#     "lb-paas-web-rule" = {
#       protocol      = "Tcp"
#       frontend_port = var.cw-paas-app-port
#       backend_port  = 443
#     }
#   }
# }