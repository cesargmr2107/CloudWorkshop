terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
  backend "azurerm" {
      resource_group_name  = "cw-common-resources"
      storage_account_name = "cwterraformbackend"
      container_name       = "terraform-backend"
      key                  = "terraform.tfstate"
  }

}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "ws-iaas-app-rg" {
  name     = "ws-iaas-app-rg"
  location = "westeurope"
}