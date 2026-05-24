variable "name" {
  description = "Name of the private endpoint."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where the private endpoint will be created."
  type        = string
}

variable "location" {
  description = "Azure region for the private endpoint."
  type        = string
}

variable "subnet_id" {
  description = "ID of the private endpoint subnet."
  type        = string
}

variable "private_connection_resource_id" {
  description = "Resource ID of the PaaS service to connect privately (ACR, Key Vault, MySQL, etc.)."
  type        = string
}

variable "subresource_names" {
  description = "Subresource type for the PaaS service (e.g. ['registry'], ['vault'], ['mysqlServer'])."
  type        = list(string)
}

variable "private_dns_zone_ids" {
  description = "List of private DNS zone IDs to register the endpoint IP into."
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to the private endpoint."
  type        = map(string)
  default     = {}
}
