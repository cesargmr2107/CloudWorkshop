// EXISTING RESOURCE GROUP FOR COMMON RESOURCES
data "azurerm_resource_group" "cw-common-rg" {
  name = "cw-common-rg"
}

// EXISTING KEY VAULT
data "azurerm_key_vault" "cw-common-kv" {
  name                = "cw-common-kv"
  resource_group_name = data.azurerm_resource_group.cw-common-rg.name
}

// EXISTING BACKEND STORAGE ACCOUNT
data "azurerm_storage_account" "cwterraformbackend" {
  name                = "cwterraformbackend"
  resource_group_name = data.azurerm_resource_group.cw-common-rg.name
}

// VIRTUAL NETWORK
resource "azurerm_virtual_network" "cw-common-vnet" {
  name                = "cw-common-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.cw-common-rg.location
  resource_group_name = data.azurerm_resource_group.cw-common-rg.name
}

// VIRTUAL NETWORK SUBNETS
resource "azurerm_subnet" "cw-subnets" {

  // Subnet parameters definition
  for_each = {
    "cw-app-gateway-subnet"      = ["10.0.0.0/24"],
    "cw-iaas-web-app-subnet"     = ["10.0.1.0/24"],
    "cw-paas-web-app-pe-subnet"  = ["10.0.2.0/24"],
    "cw-paas-web-app-int-subnet" = ["10.0.3.0/24"],
    "cw-data-subnet"          = ["10.0.4.0/24"]
  }

  // Subnet parameters assignment 
  name                 = each.key
  address_prefixes     = each.value
  resource_group_name  = azurerm_virtual_network.cw-common-vnet.resource_group_name
  virtual_network_name = azurerm_virtual_network.cw-common-vnet.name

  // Delegation for App Service VNet Integration if subnet is "cw-paas-web-app-int-subnet"
  dynamic "delegation" {
    for_each = each.key == "cw-paas-web-app-int-subnet" ? toset([1]) : toset([])
    content {
      name = "delegation"
      service_delegation {
        name = "Microsoft.Web/serverFarms"
        actions = [
          "Microsoft.Network/virtualNetworks/subnets/action"
        ]
      }
    }
  }
}

// NETWORK SECURITY GROUP
resource "azurerm_network_security_group" "cw-common-nsg" {
  name                = "cw-common-nsg"
  location            = data.azurerm_resource_group.cw-common-rg.location
  resource_group_name = data.azurerm_resource_group.cw-common-rg.name

}

// Allow web traffic from Internet
resource "azurerm_network_security_rule" "cw-common-nsg-rule1" {
  network_security_group_name = azurerm_network_security_group.cw-common-nsg.name
  resource_group_name         = azurerm_network_security_group.cw-common-nsg.resource_group_name
  name                        = "AllowWebFromInternet"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = [var.cw-iaas-app-port, var.cw-paas-app-port]
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

// Allow incoming Internet traffic to App Gateway
resource "azurerm_network_security_rule" "cw-common-nsg-rule2" {
  network_security_group_name = azurerm_network_security_group.cw-common-nsg.name
  resource_group_name         = azurerm_network_security_group.cw-common-nsg.resource_group_name
  name                        = "AllowIncomingAppGateway"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "65200-65535"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_subnet_network_security_group_association" "cw-common-nsg-association" {
  for_each                  = azurerm_subnet.cw-subnets
  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.cw-common-nsg.id
}

// APP GATEWAY

resource "azurerm_public_ip" "cw-app-gateway-public-ip" {
  name                = "cw-app-gateway-public-ip"
  sku                 = "Standard"
  location            = data.azurerm_resource_group.cw-common-rg.location
  resource_group_name = data.azurerm_resource_group.cw-common-rg.name
  allocation_method   = "Static"
}

resource "azurerm_application_gateway" "cw-app-gateway" {

  // BASIC APP GATEWAY SETTINGS
  name                = "cw-app-gateway"
  resource_group_name = data.azurerm_resource_group.cw-common-rg.name
  location            = data.azurerm_resource_group.cw-common-rg.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "cw-app-gateway-subnet-configuration"
    subnet_id = azurerm_subnet.cw-subnets["cw-app-gateway-subnet"].id
  }

  frontend_ip_configuration {
    name                 = "cw-app-gateway-frontend-ip-config"
    public_ip_address_id = azurerm_public_ip.cw-app-gateway-public-ip.id
  }

  // IAAS BACKEND SETTINGS

  frontend_port {
    name = "cw-app-gateway-iaas-frontend-port"
    port = var.cw-iaas-app-port
  }

  backend_address_pool {
    name         = "cw-app-gateway-iaas-backend-pool"
    ip_addresses = azurerm_network_interface.cw-iaas-app-vm-nic.private_ip_addresses
  }

  probe {
    name                = "cw-app-gateway-iaas-probe"
    host                = "127.0.0.1"
    interval            = 10
    timeout             = 60
    unhealthy_threshold = 1
    port                = 80
    protocol            = "Http"
    path                = "/"
  }

  backend_http_settings {
    name                  = "cw-app-gateway-iaas-backend-http-settings"
    probe_name            = "cw-app-gateway-iaas-probe"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
  }

  http_listener {
    name                           = "cw-app-gateway-iaas-listener"
    frontend_ip_configuration_name = "cw-app-gateway-frontend-ip-config"
    frontend_port_name             = "cw-app-gateway-iaas-frontend-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "cw-app-gateway-iaas-routing-rule"
    rule_type                  = "Basic"
    priority                   = 10
    http_listener_name         = "cw-app-gateway-iaas-listener"
    backend_address_pool_name  = "cw-app-gateway-iaas-backend-pool"
    backend_http_settings_name = "cw-app-gateway-iaas-backend-http-settings"
  }

  // PAAS BACKEND SETTINGS

  frontend_port {
    name = "cw-app-gateway-paas-frontend-port"
    port = var.cw-paas-app-port
  }

  backend_address_pool {
    name  = "cw-app-gateway-paas-backend-pool"
    fqdns = [azurerm_linux_web_app.cw-paas-app-asw.default_hostname]
  }

  probe {
    name                                      = "cw-app-gateway-paas-probe"
    pick_host_name_from_backend_http_settings = true
    interval                                  = 10
    timeout                                   = 60
    unhealthy_threshold                       = 1
    port                                      = 443
    protocol                                  = "Https"
    path                                      = "/"
  }

  backend_http_settings {
    name                                = "cw-app-gateway-paas-backend-http-settings"
    probe_name                          = "cw-app-gateway-paas-probe"
    pick_host_name_from_backend_address = true
    cookie_based_affinity               = "Disabled"
    port                                = 443
    protocol                            = "Https"
    request_timeout                     = 1
  }

  http_listener {
    name                           = "cw-app-gateway-paas-listener"
    frontend_ip_configuration_name = "cw-app-gateway-frontend-ip-config"
    frontend_port_name             = "cw-app-gateway-paas-frontend-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "cw-app-gateway-paas-routing-rule"
    rule_type                  = "Basic"
    priority                   = 20
    http_listener_name         = "cw-app-gateway-paas-listener"
    backend_address_pool_name  = "cw-app-gateway-paas-backend-pool"
    backend_http_settings_name = "cw-app-gateway-paas-backend-http-settings"
  }
}
