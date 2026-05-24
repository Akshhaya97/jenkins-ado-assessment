# locals {
#   merged_app_settings = merge(
#     {
#       WEBSITES_PORT                         = "8080"
#       APPLICATIONINSIGHTS_CONNECTION_STRING = var.application_insights_connection
#       KEY_VAULT_NAME                        = var.key_vault_name
#     },
#     var.app_settings
#   )
# }


resource "azurerm_linux_web_app" "this" {
  name                = var.linux_web_app_name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = var.service_plan_id
  https_only          = true
  tags                = var.tags

  site_config {
    always_on = true

    application_stack {
      docker_image_name        = var.container_image_name
      docker_registry_url      = "https://${var.container_registry_login_server}"
      docker_registry_username = var.container_registry_username
      docker_registry_password = var.container_registry_password
    }
  }

  app_settings = var.app_settings

  # VNet integration routes all outbound traffic through the app service subnet
  virtual_network_subnet_id = var.virtual_network_subnet_id
}
