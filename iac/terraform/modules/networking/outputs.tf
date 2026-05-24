
output "vnet_id" {
  description = "Resource ID of the Virtual Network."
  value       = azurerm_virtual_network.petclinic_vnet.id
}

output "vnet_name" {
  description = "Name of the Virtual Network."
  value       = azurerm_virtual_network.petclinic_vnet.name
}

output "firewall_subnet_id" {
  description = "Resource ID of the Azure Firewall subnet."
  value       = azurerm_subnet.firewall.id
}

output "appgw_subnet_id" {
  description = "Resource ID of the Application Gateway subnet."
  value       = azurerm_subnet.app_gateway.id
}

output "app_subnet_id" {
  description = "Resource ID of the App Service integration subnet."
  value       = azurerm_subnet.app_service.id
}

output "agent_subnet_id" {
  description = "Resource ID of the self-hosted agent subnet."
  value       = azurerm_subnet.agent.id
}

output "private_endpoint_subnet_id" {
  description = "Resource ID of the private endpoint subnet."
  value       = azurerm_subnet.private_endpoint.id
}
