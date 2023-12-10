resource "azurerm_private_endpoint" "endpoint" {
  name                = format("%s-%s", var.private_link_enabled_resource_name, "endpoint")
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_dns_zone_group {
    name                 = format("%s-%s", var.private_link_enabled_resource_name, "privatednszonegroup")
    private_dns_zone_ids = [var.private_dns_zone_id]
  }

  private_service_connection {
    name                           = format("%s-%s", var.private_link_enabled_resource_name, "privateserviceconnection")
    private_connection_resource_id = var.private_link_enabled_resource_id
    is_manual_connection           = false
    subresource_names              = var.subresource_names
  }
}

# resource "azurerm_private_dns_a_record" "dns_a" {
#   name                = var.private_link_enabled_resource_name
#   zone_name           = var.private_dns_zone_name
#   resource_group_name = var.resource_group_name
#   ttl                 = 300
#   records             = [azurerm_private_endpoint.endpoint.private_service_connection.0.private_ip_address]
# }