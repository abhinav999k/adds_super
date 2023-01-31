resource "azurerm_resource_group" "adds_rg" {
  name     = "a-adds-rg"
  location = "Norway east"
}

resource "azurerm_virtual_network" "adds_rg" {
  name                = "adds_rg-vnet"
  location            = azurerm_resource_group.adds_rg.location
  resource_group_name = azurerm_resource_group.adds_rg.name
  address_space       = ["10.124.1.0/27"]
}

resource "azurerm_subnet" "adds_rg" {
  name                 = "adds_rg-subnet"
  resource_group_name  = azurerm_resource_group.adds_rg.name
  virtual_network_name = azurerm_virtual_network.adds_rg.name
  address_prefixes     = ["10.124.1.0/28"]
}

resource "azurerm_network_security_group" "adds_rg" {
  name                = "adds_rg-nsg"
  location            = azurerm_resource_group.adds_rg.location
  resource_group_name = azurerm_resource_group.adds_rg.name

  security_rule {
    name                       = "AllowSyncWithAzureAD"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "AzureActiveDirectoryDomainServices"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowRD"
    priority                   = 201
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "CorpNetSaw"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowPSRemoting"
    priority                   = 301
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5986"
    source_address_prefix      = "AzureActiveDirectoryDomainServices"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowLDAPS"
    priority                   = 401
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "636"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "adds_rg" {
  subnet_id                 = azurerm_subnet.adds_rg.id
  network_security_group_id = azurerm_network_security_group.adds_rg.id
}

resource "azuread_group" "dc_admins" {
  display_name     = "AAD DC Administrators"
  security_enabled = true
}

resource "azuread_user" "admin" {
  user_principal_name = "dc-admin@hashicorp-example.com"
  display_name        = "DC Administrator"
  password            = "Pa55w0Rd!!1"
}

resource "azuread_group_member" "admin" {
  group_object_id  = azuread_group.dc_admins.object_id
  member_object_id = azuread_user.admin.object_id
}

resource "azuread_service_principal" "examplea" {
  application_id = "2565bd9d-da50-47d4-8b85-4c97f669dc36" // published app for domain services
}


resource "azurerm_active_directory_domain_service" "widgets" {
  name                = "widgets-com"
  location            = azurerm_resource_group.adds_rg.location
  resource_group_name = azurerm_resource_group.adds_rg.name

  domain_name           = "widgetslogin.net"
  sku                   = "Standard"
  filtered_sync_enabled = false

  initial_replica_set {
    subnet_id = azurerm_subnet.adds_rg.id
  }

  notifications {
    additional_recipients = ["notifyA@example.net", "notifyB@example.org"]
    notify_dc_admins      = true
    notify_global_admins  = true
  }

  security {
    sync_kerberos_passwords = true
    sync_ntlm_passwords     = true
    sync_on_prem_passwords  = true
  }

  tags = {
    Environment = "prod"
  }

  depends_on = [
    azuread_service_principal.example,
    azurerm_subnet_network_security_group_association.adds_rg,
  ]
}