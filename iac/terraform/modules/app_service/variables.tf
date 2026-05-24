variable "service_plan_id" {
  type = string
}

variable "service_plan_name" {
  type = string
}

variable "linux_web_app_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "sku_name" {
  type = string
}

variable "container_image_name" {
  type = string
}

variable "container_registry_login_server" {
  type = string
}

variable "container_registry_username" {
  type      = string
  sensitive = true
}

variable "container_registry_password" {
  type      = string
  sensitive = true
}

variable "application_insights_connection" {
  type    = string
  default = ""
}

variable "key_vault_name" {
  type    = string
  default = ""
}

variable "app_settings" {
  type    = map(string)
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "user_assigned_identity_client_id" {
  type    = string
  default = ""
}

variable "virtual_network_subnet_id" {
  description = "Subnet ID for App Service outbound VNet integration. Pass null to disable."
  type        = string
  default     = null
}