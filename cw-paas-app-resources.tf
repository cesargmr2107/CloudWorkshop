resource "azurerm_resource_group" "cw-paas-app-rg" {
  name     = "cw-paas-app-rg"
  location = var.location
}

resource "azurerm_service_plan" "cw-paas-app-asp" {
  name                = "cw-paas-app-asp"
  resource_group_name = azurerm_resource_group.cw-paas-app-rg.name
  location            = azurerm_resource_group.cw-paas-app-rg.location
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "cw-paas-app-asw" {

  // Basic info
  name                = "cw-paas-app-asw"
  resource_group_name = azurerm_resource_group.cw-paas-app-rg.name
  location            = azurerm_resource_group.cw-paas-app-rg.location
  service_plan_id     = azurerm_service_plan.cw-paas-app-asp.id

  // Settings

  https_only = true

  virtual_network_subnet_id = azurerm_subnet.cw-subnets["cw-paas-web-app-int-subnet"].id

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

  // Connection string for DB access
  connection_string {
    type  = "SQLAzure"
    name  = "DB_CONNECTION_STRING"
    value = local.db_connection_string
  }

  // Application logging
  logs {
    application_logs {
      file_system_level = "Verbose"
    }
  }

}

// GITHUB CONNECTION

resource "azurerm_app_service_source_control" "cw-paas-app-source-control" {
  app_id                 = azurerm_linux_web_app.cw-paas-app-asw.id
  branch                 = "main"
  repo_url               = var.app-github-repo
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

//  Personal GitHub token (PAT) with repo and workflow permissions
resource "azurerm_source_control_token" "cw-paas-app-source-control-token" {
  type  = "GitHub"
  token = data.azurerm_key_vault_secret.github-token.value
}

data "azurerm_key_vault_secret" "github-token" {
  name         = "github-token"
  key_vault_id = data.azurerm_key_vault.cw-common-kv.id
}

// PRIVATE NETWORKING 

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
  subnet_id                          = azurerm_subnet.cw-subnets["cw-paas-web-app-pe-subnet"].id
  subresource_names                  = ["sites"]
  private_dns_zone_id                = azurerm_private_dns_zone.cw-paas-app-asw-dns-zone.id
}
