resource "azurerm_resource_group" "paas_app_rg" {
  name     = "${var.paas_app_name_prefix}-rg"
  location = var.common_location
}

resource "azurerm_service_plan" "paas_app_asp" {
  name                = "${var.paas_app_name_prefix}-asp"
  resource_group_name = azurerm_resource_group.paas_app_rg.name
  location            = azurerm_resource_group.paas_app_rg.location
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "paas_app_asw" {

  # Basic info
  name                = "${var.paas_app_name_prefix}-asw"
  resource_group_name = azurerm_resource_group.paas_app_rg.name
  location            = azurerm_resource_group.paas_app_rg.location
  service_plan_id     = azurerm_service_plan.paas_app_asp.id

  # Settings

  https_only = true

  virtual_network_subnet_id = azurerm_subnet.common_subnets["cw-paas-web-app-int-subnet"].id

  site_config {
    always_on                   = true
    default_documents           = ["index.html"]
    ftps_state                  = "Disabled"
    managed_pipeline_mode       = "Integrated"
    minimum_tls_version         = "1.2"
    scm_minimum_tls_version     = "1.2"
    scm_use_main_ip_restriction = false
    use_32_bit_worker           = true
    application_stack {
      python_version = "3.9"
    }
    ip_restriction {
      name       = "DenyAllInternetTraffic"
      action     = "Deny"
      ip_address = "0.0.0.0/0"
    }
    scm_ip_restriction {
      name       = "AllowAllDeploymentTraffic"
      action     = "Allow"
      ip_address = "0.0.0.0/0"
    }
  }

  # Connection string for DB access
  connection_string {
    type  = "SQLAzure"
    name  = "DB_CONNECTION_STRING"
    value = local.db_connection_string
  }

  # Application logging
  logs {
    application_logs {
      file_system_level = "Verbose"
    }
  }

}

# GITHUB CONNECTION

resource "azurerm_app_service_source_control" "paas_app_source_control" {
  app_id                 = azurerm_linux_web_app.paas_app_asw.id
  branch                 = "main"
  repo_url               = var.common_app_github_repo
  rollback_enabled       = false
  use_manual_integration = false
  use_mercurial          = false

  github_action_configuration {
    generate_workflow_file = true
    code_configuration {
      runtime_stack   = "python"
      runtime_version = "3.9"
    }
  }

}

#  Personal GitHub token (PAT) with repo and workflow permissions
resource "azurerm_source_control_token" "paas_app_source_control_token" {
  type  = "GitHub"
  token = data.azurerm_key_vault_secret.github_token.value
}

data "azurerm_key_vault_secret" "github_token" {
  name         = var.paas_app_source_control_token
  key_vault_id = data.azurerm_key_vault.common_kv.id
}

# PRIVATE NETWORKING 

resource "azurerm_private_dns_zone" "paas_app_asw_dns_zone" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.paas_app_rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "paas_app_asw_dns_zone_link" {
  name                  = "${var.paas_app_name_prefix}-asw-dns-zone-link"
  resource_group_name   = azurerm_resource_group.paas_app_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.paas_app_asw_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.common_vnet.id
}

module "paas_app_asw_endpoint" {
  source                             = "./tf_modules/private_endpoint"
  location                           = azurerm_resource_group.paas_app_rg.location
  resource_group_name                = azurerm_resource_group.paas_app_rg.name
  private_link_enabled_resource_name = azurerm_linux_web_app.paas_app_asw.name
  private_link_enabled_resource_id   = azurerm_linux_web_app.paas_app_asw.id
  subnet_id                          = azurerm_subnet.common_subnets["cw-paas-web-app-pe-subnet"].id
  subresource_names                  = ["sites"]
  private_dns_zone_id                = azurerm_private_dns_zone.paas_app_asw_dns_zone.id
}
