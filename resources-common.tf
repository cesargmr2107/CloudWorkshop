// EXISTING BACKEND STORAGE ACCOUNT
data "azurerm_storage_account" "common_terraform_backend" {
  name                = var.common_terraform_backend_name
  resource_group_name = var.common_terraform_backend_rg
}

// EXISTING RESOURCE GROUP FOR COMMON RESOURCES
data "azurerm_resource_group" "common_rg" {
  name = var.common_terraform_backend_rg
}

// EXISTING KEY VAULT
data "azurerm_key_vault" "common_kv" {
  name                = "${var.common_name_prefix}-kv"
  resource_group_name = var.common_terraform_backend_rg
}

// VIRTUAL NETWORK
resource "azurerm_virtual_network" "common_vnet" {
  name                = "${var.common_name_prefix}-vnet"
  address_space       = [var.common_vnet_range]
  location            = data.azurerm_resource_group.common_rg.location
  resource_group_name = var.common_terraform_backend_rg
}

// VIRTUAL NETWORK SUBNETS
resource "azurerm_subnet" "common_subnets" {

  // Subnet parameters definition
  for_each = local.common_subnet_info

  // Subnet parameters assignment 
  name                 = each.key
  address_prefixes     = [each.value]
  resource_group_name  = azurerm_virtual_network.common_vnet.resource_group_name
  virtual_network_name = azurerm_virtual_network.common_vnet.name

  // Delegation for App Service VNet Integration if subnet is "cw-paas-web_app-int-subnet"
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
resource "azurerm_network_security_group" "common_nsg" {
  name                = "${var.common_name_prefix}-nsg"
  location            = data.azurerm_resource_group.common_rg.location
  resource_group_name = var.common_terraform_backend_rg

}

// Allow web traffic from Internet
resource "azurerm_network_security_rule" "common_nsg_rule_AllowWebFromInternet" {
  network_security_group_name = azurerm_network_security_group.common_nsg.name
  resource_group_name         = azurerm_network_security_group.common_nsg.resource_group_name
  name                        = "AllowWebFromInternet"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = [var.iaas_app_frontend_port, var.paas_app_frontend_port]
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

// Allow incoming Internet traffic to App Gateway
resource "azurerm_network_security_rule" "common_nsg_rule_AllowIncomingAppGateway" {
  network_security_group_name = azurerm_network_security_group.common_nsg.name
  resource_group_name         = azurerm_network_security_group.common_nsg.resource_group_name
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

resource "azurerm_subnet_network_security_group_association" "common_nsg_association" {
  for_each                  = azurerm_subnet.common_subnets
  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.common_nsg.id
}

// APP GATEWAY

resource "azurerm_public_ip" "common_gateway_public_ip" {
  name                = "${var.common_name_prefix}-gateway-public-ip"
  sku                 = "Standard"
  location            = data.azurerm_resource_group.common_rg.location
  resource_group_name = var.common_terraform_backend_rg
  allocation_method   = "Static"
}

resource "azurerm_application_gateway" "common_gateway" {

  // BASIC APP GATEWAY SETTINGS
  name                = "${var.common_name_prefix}-gateway"
  resource_group_name = var.common_terraform_backend_rg
  location            = data.azurerm_resource_group.common_rg.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "${var.common_name_prefix}-gateway-subnet-configuration"
    subnet_id = azurerm_subnet.common_subnets["cw-common-gateway-subnet"].id
  }

  frontend_ip_configuration {
    name                 = "${var.common_name_prefix}-gateway-frontend-ip-config"
    public_ip_address_id = azurerm_public_ip.common_gateway_public_ip.id
  }

  # BACKEND SETTINGS

  dynamic "frontend_port" {
    for_each = local.common_gateway_settings
    content {
      name = "${frontend_port.key}-frontend-port"
      port = frontend_port.value.frontend_port
    }
  }

  dynamic "backend_address_pool" {
    for_each = local.common_gateway_settings
    content {
      name         = "${backend_address_pool.key}-backend-pool"
      ip_addresses = backend_address_pool.value.backend_address_pool.ip_addresses
      fqdns        = backend_address_pool.value.backend_address_pool.fqdns
    }
  }

  dynamic "probe" {
    for_each = local.common_gateway_settings
    content {
      name                                      = "${probe.key}-probe"
      port                                      = probe.value.backend_port
      protocol                                  = probe.value.backend_protocol
      interval                                  = 10
      timeout                                   = 60
      unhealthy_threshold                       = 1
      path                                      = "/"
      pick_host_name_from_backend_http_settings = true
    }
  }

  dynamic "backend_http_settings" {
    for_each = local.common_gateway_settings
    content {
      name                                = "${backend_http_settings.key}-backend-http-settings"
      probe_name                          = "${backend_http_settings.key}-probe"
      port                                = backend_http_settings.value.backend_port
      protocol                            = backend_http_settings.value.backend_protocol
      cookie_based_affinity               = "Disabled"
      request_timeout                     = 1
      pick_host_name_from_backend_address = true
    }
  }

  dynamic "http_listener" {
    for_each = local.common_gateway_settings
    content {
      name                           = "${http_listener.key}-listener"
      frontend_port_name             = "${http_listener.key}-frontend-port"
      frontend_ip_configuration_name = "${var.common_name_prefix}-gateway-frontend-ip-config"
      protocol                       = http_listener.value.frontend_protocol
    }
  }

  dynamic "request_routing_rule" {
    for_each = local.common_gateway_settings
    content {
      name                       = "${request_routing_rule.key}-routing-rule"
      http_listener_name         = "${request_routing_rule.key}-listener"
      backend_address_pool_name  = "${request_routing_rule.key}-backend-pool"
      backend_http_settings_name = "${request_routing_rule.key}-backend-http-settings"
      priority                   = request_routing_rule.value.request_routing_rule_priority
      rule_type                  = "Basic"
    }
  }
}
