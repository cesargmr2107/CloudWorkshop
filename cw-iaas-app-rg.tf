// RESOURCE GROUP
resource "azurerm_resource_group" "cw-iaas-app-rg" {
  name     = "cw-iaas-app-rg"
  location = "westeurope"
}

// VIRTUAL MACHINE
resource "azurerm_linux_virtual_machine" "cw-iaas-app-vm" {
  name                            = "cw-iaas-app-vm"
  resource_group_name             = azurerm_resource_group.cw-iaas-app-rg.name
  location                        = azurerm_resource_group.cw-iaas-app-rg.location
  size                            = "Standard_B1s"
  admin_username                  = "adminuser"
  admin_password                  = data.azurerm_key_vault_secret.vm-secret.value
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.cw-iaas-app-vm-nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

// VIRTUAL MACHINE ADMIN SECRET FROM KEY VAULT
data "azurerm_key_vault_secret" "vm-secret" {
  name         = "vm-secret"
  key_vault_id = data.azurerm_key_vault.cw-common-kv.id
}


// VIRTUAL MACHINE NIC
resource "azurerm_network_interface" "cw-iaas-app-vm-nic" {
  name                = "cw-iaas-app-vm-nic"
  location            = azurerm_resource_group.cw-iaas-app-rg.location
  resource_group_name = azurerm_resource_group.cw-iaas-app-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.cw-subnets["cw-iaas-app-internal"].id
    private_ip_address_allocation = "Dynamic"
  }
}