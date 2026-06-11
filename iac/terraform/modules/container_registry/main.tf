resource "azurerm_container_registry" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = var.sku
  admin_enabled                 = var.admin_enabled
  tags                          = var.tags
  
  zone_redundancy_enabled       = var.zone_redundancy_enabled
  data_endpoint_enabled         = var.data_endpoint_enabled
  public_network_access_enabled = var.public_network_access_enabled
}