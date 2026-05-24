output "app_name" {
  value = azurerm_linux_web_app.this.name
}

output "app_url" {
  value = "https://${azurerm_linux_web_app.this.default_hostname}"
}

output "hostname" {
  description = "Default hostname of the App Service (used as App Gateway backend FQDN)."
  value       = azurerm_linux_web_app.this.default_hostname
}