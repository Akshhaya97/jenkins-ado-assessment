output "server_fqdn" {
  description = "Fully qualified domain name of the MySQL server."
  value       = azurerm_mysql_flexible_server.this.fqdn
}

output "server_name" {
  description = "Name of the MySQL server."
  value       = azurerm_mysql_flexible_server.this.name
}

output "server_id" {
  description = "Resource ID of the MySQL server (used for private endpoint)."
  value       = azurerm_mysql_flexible_server.this.id
}

output "database_name" {
  description = "Name of the created database."
  value       = azurerm_mysql_flexible_database.this.name
}

output "jdbc_url" {
  description = "JDBC connection URL for Spring Boot."
  value       = "jdbc:mysql://${azurerm_mysql_flexible_server.this.fqdn}:3306/${azurerm_mysql_flexible_database.this.name}?useSSL=true&requireSSL=true"
}
