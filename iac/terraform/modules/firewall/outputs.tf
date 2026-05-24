output "firewall_private_ip" {
  description = "Private IP of the Azure Firewall (used as next hop in route tables)."
  value       = azurerm_firewall.this.ip_configuration[0].private_ip_address
}

output "route_table_id" {
  description = "ID of the route table that forces traffic through the firewall."
  value       = azurerm_route_table.this.id
}
