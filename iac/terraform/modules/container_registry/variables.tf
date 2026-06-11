variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "sku" {
  type    = string
  default = "Basic"
}

variable "admin_enabled" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "zone_redundancy_enabled" {
  type        = bool
  default     = false
  description = "Whether zone redundancy is enabled for this Container Registry. Corresponds to domain name label scope in Azure Portal. Requires Premium SKU."
}

variable "data_endpoint_enabled" {
  type        = bool
  default     = false
  description = "Whether to enable dedicated data endpoints for this Container Registry. Requires Premium SKU."
}

variable "public_network_access_enabled" {
  type        = bool
  default     = true
  description = "Whether public network access is allowed for the container registry."
}