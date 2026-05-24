variable "zone_name" {
  description = "Private DNS zone name (e.g. privatelink.azurecr.io)."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where the DNS zone will be created."
  type        = string
}

variable "virtual_network_id" {
  description = "ID of the VNet to link this DNS zone to."
  type        = string
}

variable "tags" {
  description = "Tags to apply to the DNS zone."
  type        = map(string)
  default     = {}
}
