# RESOURCE GROUP
resource "azurerm_resource_group" "data_rg" {
  name     = "${var.data_name_prefix}-rg"
  location = var.common_location
}

# MSSQL SERVER & DATABASE
resource "azurerm_mssql_server" "mssql_server" {
  name                = "${var.data_name_prefix}-mssql-server"
  resource_group_name = azurerm_resource_group.data_rg.name
  location            = azurerm_resource_group.data_rg.location
  version             = "12.0"
  minimum_tls_version = "1.2"

  # SQL Administrator
  administrator_login          = var.data_db_admin
  administrator_login_password = data.azurerm_key_vault_secret.db_secret.value

}

data "azurerm_key_vault_secret" "db_secret" {
  name         = var.data_db_secret
  key_vault_id = data.azurerm_key_vault.common_kv.id
}

resource "azurerm_mssql_database" "mssql_db" {
  name                        = "${var.data_name_prefix}-mssql-db"
  server_id                   = azurerm_mssql_server.mssql_server.id
  collation                   = "SQL_Latin1_General_CP1_CI_AS"
  license_type                = "LicenseIncluded"
  auto_pause_delay_in_minutes = 60
  sku_name                    = "Basic"
  storage_account_type        = "Local"

  # Import initial DB setup from Terraform storage account backend
  import {
    storage_uri                  = "${data.azurerm_storage_account.common_terraform_backend.primary_blob_endpoint}${var.data_db_setup_bacpac_path}"
    storage_key                  = data.azurerm_storage_account.common_terraform_backend.primary_access_key
    administrator_login          = var.data_db_admin
    administrator_login_password = data.azurerm_key_vault_secret.db_secret.value
    storage_key_type             = "StorageAccessKey"
    authentication_type          = "Sql"
  }
}

# Allow trusted Azure services
# Note: this option is necessary for the DB import, since the Terraform pipeline
# is not integrated on the private network
resource "azurerm_mssql_firewall_rule" "AllowTrustedAzureServices" {
  name             = "AllowTrustedAzureServices"
  server_id        = azurerm_mssql_server.mssql_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# PRIVATE NETWORKING 

resource "azurerm_private_dns_zone" "data_dns_zone" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.data_rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "data_dns_zone_link" {
  name                  = "${var.data_name_prefix}-dns-zone-link"
  resource_group_name   = azurerm_resource_group.data_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.data_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.common_vnet.id
}

module "mssql_server_endpoint" {
  source                             = "./tf_modules/private_endpoint"
  location                           = azurerm_resource_group.data_rg.location
  resource_group_name                = azurerm_resource_group.data_rg.name
  private_link_enabled_resource_name = azurerm_mssql_server.mssql_server.name
  private_link_enabled_resource_id   = azurerm_mssql_server.mssql_server.id
  subnet_id                          = azurerm_subnet.common_subnets["cw-data-subnet"].id
  subresource_names                  = ["sqlServer"]
  private_dns_zone_id                = azurerm_private_dns_zone.data_dns_zone.id
}
