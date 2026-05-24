# Private DNS Zone — required for private endpoint name resolution within the VNet
resource "azurerm_private_dns_zone" "this" {
  name                = var.zone_name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Link the DNS zone to the VNet so all resources inside can resolve private FQDNs
resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  name                  = "${replace(var.zone_name, ".", "-")}-vnet-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
  tags                  = var.tags
}
