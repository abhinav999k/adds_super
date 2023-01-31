terraform {
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
}

provider "azurerm" {
  subscription_id = "46aa4e0d-9dd3-4108-85e4-a2aa5e6a1443"
  features {}
}

provider "azuread" {

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