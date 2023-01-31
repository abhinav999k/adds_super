terraform {
  backend "azurerm" {
    subscription_id      = "46aa4e0d-9dd3-4108-85e4-a2aa5e6a1443"
    resource_group_name  = "atfadds"
    storage_account_name = "atfadds"
    container_name       = "tfstate"
    key                  = "lol.tfstate"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.38.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.33.0"
    }
  }
  required_version = "1.3.7"
}

provider "azurerm" {
  subscription_id = "46aa4e0d-9dd3-4108-85e4-a2aa5e6a1443"
  features {}
}

resource "azuread_application" "example" {
  display_name = "example"
}

resource "azuread_service_principal" "example" {
  application_id = azuread_application.example.application_id
}

resource "azuread_service_principal_password" "example" {
  service_principal_id = azuread_service_principal.example.object_id
}