output "common_gateway_public_ip" {
  value = azurerm_public_ip.common_gateway_public_ip.ip_address
}