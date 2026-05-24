resource "azurerm_service_plan" "pet_clinic_service_plan" {
  name                = var.app_service_plan_name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = var.app_service_plan_os_type
  sku_name            = var.app_service_plan_sku_name
}