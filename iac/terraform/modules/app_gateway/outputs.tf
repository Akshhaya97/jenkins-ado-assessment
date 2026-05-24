output "public_ip_address" {
  description = "Public IP address of the Application Gateway."
  value       = azurerm_public_ip.app_gateway.ip_address
}

output "app_gateway_id" {
  description = "Resource ID of the Application Gateway."
  value       = azurerm_application_gateway.this.id
}
