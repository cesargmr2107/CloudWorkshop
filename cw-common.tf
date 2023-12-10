// EXISTING RESOURCE GROUP FOR COMMON RESOURCES
data "azurerm_resource_group" "cw-common-rg" {
  name = "cw-common-rg"
}

// EXISTING KEY VAULT
data "azurerm_key_vault" "cw-common-kv" {
  name                = "cw-common-kv"
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
    "cw-gateway-subnet"            = ["10.0.0.0/24"]
    "cw-iaas-web-app"              = ["10.0.1.0/24"],
    "cw-paas-web-app-frontend-pe"  = ["10.0.2.0/24"],
    "cw-paas-web-app-frontend-int" = ["10.0.3.0/24"],
    "cw-paas-web-app-backend"      = ["10.0.4.0/24"]
  }

  // Subnet parameters assignment 
  name                 = each.key
  address_prefixes     = each.value
  resource_group_name  = azurerm_virtual_network.cw-common-vnet.resource_group_name
  virtual_network_name = azurerm_virtual_network.cw-common-vnet.name
}

// NETWORK SECURITY GROUP
resource "azurerm_network_security_group" "cw-common-nsg" {
  name                = "cw-common-nsg"
  location            = data.azurerm_resource_group.cw-common-rg.location
  resource_group_name = data.azurerm_resource_group.cw-common-rg.name

}

# Allow web traffic from Internet
resource "azurerm_network_security_rule" "cw-common-nsg-rule1" {
  network_security_group_name = azurerm_network_security_group.cw-common-nsg.name
  resource_group_name         = azurerm_network_security_group.cw-common-nsg.resource_group_name
  name                        = "AllowWebFromInternet"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = "*"
  destination_address_prefix  = "VirtualNetwork"
}

# Allow incoming Internet traffic to App Gateway
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
  destination_address_prefix  = azurerm_subnet.cw-subnets["cw-gateway-subnet"].address_prefixes[0]
}

resource "azurerm_subnet_network_security_group_association" "cw-common-nsg-association" {
  for_each                  = azurerm_subnet.cw-subnets
  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.cw-common-nsg.id
}


// LOAD BALANCER
resource "azurerm_lb" "cw-common-lb" {
  name                = "cw-common-lb"
  sku                 = "Standard"
  location            = data.azurerm_resource_group.cw-common-rg.location
  resource_group_name = data.azurerm_resource_group.cw-common-rg.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.cw-common-lb-public-ip.id
  }
}

resource "azurerm_public_ip" "cw-common-lb-public-ip" {
  name                = "cw-common-lb-public-ip"
  sku                 = "Standard"
  location            = data.azurerm_resource_group.cw-common-rg.location
  resource_group_name = data.azurerm_resource_group.cw-common-rg.name
  allocation_method   = "Static"
}

