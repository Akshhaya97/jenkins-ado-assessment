# Private Endpoint — connects a PaaS service into the VNet over a private IP
resource "azurerm_private_endpoint" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${var.name}-connection"
    private_connection_resource_id = var.private_connection_resource_id
    subresource_names              = var.subresource_names
    is_manual_connection           = false
  }

  # Registers the private IP into the linked Private DNS Zone automatically
  private_dns_zone_group {
    name                 = "${var.name}-dns-group"
    private_dns_zone_ids = var.private_dns_zone_ids
  }

  tags = var.tags
}
