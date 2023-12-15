locals {
  db_connection_string = "Driver={ODBC Driver 18 for SQL Server};Server=tcp:${azurerm_mssql_server.cw-mssql-server.fully_qualified_domain_name},1433;Database=${azurerm_mssql_database.cw-mssql-app-db.name};Uid=${var.mssql-admin};Pwd={${data.azurerm_key_vault_secret.db-secret.value}};Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
}

