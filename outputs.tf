output "cw-common-lb-public-ip" {
  value = azurerm_public_ip.cw-common-lb-public-ip.ip_address
}