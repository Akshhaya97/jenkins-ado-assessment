variable "firewall_name" {
  description = "Name of the Azure Firewall."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where the firewall will be created."
  type        = string
}

variable "location" {
  description = "Azure region for the firewall."
  type        = string
}

variable "firewall_subnet_id" {
  description = "ID of the AzureFirewallSubnet (must be named exactly 'AzureFirewallSubnet')."
  type        = string
}

variable "tags" {
  description = "Tags to apply to firewall resources."
  type        = map(string)
  default     = {}
}
