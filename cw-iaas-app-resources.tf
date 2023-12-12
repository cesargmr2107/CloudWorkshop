// RESOURCE GROUP
resource "azurerm_resource_group" "cw-iaas-app-rg" {
  name     = "cw-iaas-app-rg"
  location = "westeurope"
}

// VIRTUAL MACHINE
resource "azurerm_linux_virtual_machine" "cw-iaas-app-vm" {

  // Basic info
  name                = "cw-iaas-app-vm"
  resource_group_name = azurerm_resource_group.cw-iaas-app-rg.name
  location            = azurerm_resource_group.cw-iaas-app-rg.location
  size                = "Standard_B1s"
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  // User data
  user_data = filebase64("./cw-iaas-app-user-data.sh")

  // Credentials
  admin_username                  = "adminuser"
  admin_password                  = data.azurerm_key_vault_secret.vm-secret.value
  disable_password_authentication = false

  // NIC assignment (NIC declared below)
  network_interface_ids = [
    azurerm_network_interface.cw-iaas-app-vm-nic.id,
  ]

  // OS version
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  // Boot diagnostics to enable serial console
  // Null value to use Microsoft managed storage account
  boot_diagnostics {
    storage_account_uri = null
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
    name                          = "cw-iaas-app-vm-nic-configuration"
    subnet_id                     = azurerm_subnet.cw-subnets["cw-iaas-web-app-subnet"].id
    private_ip_address_allocation = "Dynamic"
  }
}
