output "cw-app-gateway-public-ip" {
  value = azurerm_public_ip.cw-app-gateway-public-ip.ip_address
}