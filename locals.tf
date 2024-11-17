locals {

  # NETWORKING LOCALS
  common_subnet_number = length(var.common_subnet_list)
  common_subnet_ranges = cidrsubnets(var.common_vnet_range, [for _ in range(local.common_subnet_number) : var.common_subnet_newbits]...)
  common_subnet_info = {
    for i in range(local.common_subnet_number) : var.common_subnet_list[i] => local.common_subnet_ranges[i]
  }

  # APP GATEWAY LOCALS
  common_gateway_settings = {

    "cw-common-gateway-iaas" = {
      request_routing_rule_priority = var.iaas_app_request_routing_rule_priority
      frontend_port                 = var.iaas_app_frontend_port
      frontend_protocol             = var.iaas_app_frontend_protocol
      backend_port                  = var.iaas_app_backend_port
      backend_protocol              = var.iaas_app_backend_protocol
      backend_address_pool = {
        ip_addresses = azurerm_network_interface.iaas_app_vm_nic.private_ip_addresses
        fqdns        = null
      }
    }

    "cw-common-gateway-paas" = {
      request_routing_rule_priority = var.paas_app_request_routing_rule_priority
      frontend_port                 = var.paas_app_frontend_port
      frontend_protocol             = var.paas_app_frontend_protocol
      backend_port                  = var.paas_app_backend_port
      backend_protocol              = var.paas_app_backend_protocol
      backend_address_pool = {
        ip_addresses = null
        fqdns        = [azurerm_linux_web_app.paas_app_asw.default_hostname]
      }
    }

  }

  # DB LOCALS

  db_connection_string_options = [
    "Driver={ODBC Driver 18 for SQL Server}",
    "Server=tcp:${azurerm_mssql_server.mssql_server.fully_qualified_domain_name},1433",
    "Database=${azurerm_mssql_database.mssql_db.name}",
    "Uid=${var.data_db_admin}",
    "Pwd={${data.azurerm_key_vault_secret.db_secret.value}}",
    "Encrypt=yes",
    "TrustServerCertificate=no",
    "Connection Timeout=30"
  ]

  db_connection_string = join(";", local.db_connection_string_options)

}

