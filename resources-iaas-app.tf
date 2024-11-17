# RESOURCE GROUP
resource "azurerm_resource_group" "iaas_app_rg" {
  name     = "${var.iaas_app_name_prefix}-rg"
  location = var.common_location
}

# VIRTUAL MACHINE
resource "azurerm_linux_virtual_machine" "iaas_app_vm" {

  # Basic info
  name                = "${var.iaas_app_name_prefix}-vm"
  resource_group_name = azurerm_resource_group.iaas_app_rg.name
  location            = azurerm_resource_group.iaas_app_rg.location
  size                = "Standard_B1s"
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # User data
  user_data = base64encode(templatefile(
    "./scripts/vm_setup.sh",
    {
      vm_user              = var.iaas_app_vm_admin,
      app_repo             = var.common_app_github_repo,
      db_connection_string = local.db_connection_string
    }
  ))

  # Credentials
  admin_username                  = var.iaas_app_vm_admin
  admin_password                  = data.azurerm_key_vault_secret.vm_secret.value
  disable_password_authentication = false

  # NIC assignment (NIC declared below)
  network_interface_ids = [
    azurerm_network_interface.iaas_app_vm_nic.id,
  ]

  # OS version
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Boot diagnostics to enable serial console
  # Null value to use Microsoft managed storage account
  boot_diagnostics {
    storage_account_uri = null
  }

}

# VIRTUAL MACHINE ADMIN SECRET FROM KEY VAULT
data "azurerm_key_vault_secret" "vm_secret" {
  name         = var.iaas_app_vm_secret
  key_vault_id = data.azurerm_key_vault.common_kv.id
}

# VIRTUAL MACHINE NIC
resource "azurerm_network_interface" "iaas_app_vm_nic" {
  name                = "${var.iaas_app_name_prefix}-vm-nic"
  location            = azurerm_resource_group.iaas_app_rg.location
  resource_group_name = azurerm_resource_group.iaas_app_rg.name

  ip_configuration {
    name                          = "${var.iaas_app_name_prefix}-vm-nic-configuration"
    subnet_id                     = azurerm_subnet.common_subnets["cw-iaas-web-app-subnet"].id
    private_ip_address_allocation = "Dynamic"
  }
}
