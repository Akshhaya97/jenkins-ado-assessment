variable "app_gateway_name" {
  description = "Name of the Application Gateway."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where the Application Gateway will be created."
  type        = string
}

variable "location" {
  description = "Azure region for the Application Gateway."
  type        = string
}

variable "app_gateway_subnet_id" {
  description = "Subnet ID for the Application Gateway (dedicated subnet required)."
  type        = string
}

variable "app_service_fqdn" {
  description = "FQDN of the App Service backend (e.g. myapp.azurewebsites.net)."
  type        = string
}

variable "tags" {
  description = "Tags to apply to Application Gateway resources."
  type        = map(string)
  default     = {}
}
