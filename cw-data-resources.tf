// RESOURCE GROUP
resource "azurerm_resource_group" "cw-data-rg" {
  name     = "cw-data-rg"
  location = var.location
}

// MSSQL SERVER & DATABASE
resource "azurerm_mssql_server" "cw-mssql-server" {
  name                = "cw-mssql-server"
  resource_group_name = azurerm_resource_group.cw-data-rg.name
  location            = azurerm_resource_group.cw-data-rg.location
  version             = "12.0"
  minimum_tls_version = "1.2"

  // SQL Administrator
  administrator_login          = var.mssql-admin
  administrator_login_password = data.azurerm_key_vault_secret.db-secret.value

}

data "azurerm_key_vault_secret" "db-secret" {
  name         = "db-secret"
  key_vault_id = data.azurerm_key_vault.cw-common-kv.id
}

resource "azurerm_mssql_database" "cw-mssql-app-db" {
  name                        = "cw-mssql-app-db"
  server_id                   = azurerm_mssql_server.cw-mssql-server.id
  collation                   = "SQL_Latin1_General_CP1_CI_AS"
  license_type                = "LicenseIncluded"
  auto_pause_delay_in_minutes = 60
  sku_name                    = "Basic"
  storage_account_type        = "Local"

  // Import initial DB setup from Terraform storage account backend
  import {
    storage_uri                  = "https://cwterraformbackend.blob.core.windows.net/mssql-setup/cw-mssql-app-setup.bacpac"
    storage_key                  = data.azurerm_storage_account.cwterraformbackend.primary_access_key
    administrator_login          = var.mssql-admin
    administrator_login_password = data.azurerm_key_vault_secret.db-secret.value
    storage_key_type             = "StorageAccessKey"
    authentication_type          = "Sql"
  }
}

// Allow trusted Azure services
// Note: this option is necessary for the DB import, since the Terraform pipeline
// is not integrated on the private network
resource "azurerm_mssql_firewall_rule" "AllowTrustedAzureServices" {
  name             = "AllowTrustedAzureServices"
  server_id        = azurerm_mssql_server.cw-mssql-server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

// PRIVATE NETWORKING 

resource "azurerm_private_dns_zone" "cw-data-dns-zone" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.cw-data-rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "cw-data-dns-zone-link" {
  name                  = "cw-data-dns-zone-link"
  resource_group_name   = azurerm_resource_group.cw-data-rg.name
  private_dns_zone_name = azurerm_private_dns_zone.cw-data-dns-zone.name
  virtual_network_id    = azurerm_virtual_network.cw-common-vnet.id
}

module "cw-mssql-server-endpoint" {
  source                             = "./tf_modules/private_endpoint"
  location                           = azurerm_resource_group.cw-data-rg.location
  resource_group_name                = azurerm_resource_group.cw-data-rg.name
  private_link_enabled_resource_name = azurerm_mssql_server.cw-mssql-server.name
  private_link_enabled_resource_id   = azurerm_mssql_server.cw-mssql-server.id
  subnet_id                          = azurerm_subnet.cw-subnets["cw-data-subnet"].id
  subresource_names                  = ["sqlServer"]
  private_dns_zone_id                =azurerm_private_dns_zone.cw-data-dns-zone.id
}
