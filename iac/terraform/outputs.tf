# output "acr_login_server" {
#   description = "Azure Container Registry login server."
#   value       = module.container_registry["primary"].login_server
# }

# output "app_service_name" {
#   description = "Linux Web App name."
#   value       = module.app_service["primary"].app_name
# }

# output "app_url" {
#   description = "Default HTTPS URL for the deployed application."
#   value       = module.app_service["primary"].app_url
# }

# output "key_vault_name" {
#   description = "Key Vault name used for secrets integration."
#   value       = module.key_vault["primary"].name
# }

# output "user_assigned_identity_client_id" {
#   description = "Client ID of the user-assigned identity attached to the web app."
#   value       = module.identity["primary"].client_id
# }