variable "app_service_plan_name" {
  description = "Name of the App Service plan to create."
  type        = string
  default     = "petclinic-service-plan"
}

variable "app_service_plan_os_type" {
  description = "Operating system type for the App Service plan."
  type        = string
  default     = "Linux"
}
variable "app_service_plan_sku_name" {
  description = "SKU for the App Service plan, for example B1, P1v2, etc."
  type        = string
  default     = "B1"
}
variable "resource_group_name" {
  description = "Name of the resource group where the App Service plan will be created."
  type        = string
}

variable "location" {
  description = "Azure region where the App Service plan will be created."
  type        = string
}