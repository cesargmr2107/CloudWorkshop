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
    "cw-external"                   = ["10.0.0.0/24"],
    "cw-iaas-app-internal"          = ["10.0.1.0/24"],
    "cw-paas-app-internal-frontend" = ["10.0.2.0/24"],
    "cw-paas-app-internal-backend"  = ["10.0.3.0/24"]
  }

  // Subnet parameters assignment 
  name                 = each.key
  address_prefixes     = each.value
  resource_group_name  = azurerm_resource_group.cw-iaas-app-rg.name
  virtual_network_name = azurerm_virtual_network.cw-common-vnet.name
}
