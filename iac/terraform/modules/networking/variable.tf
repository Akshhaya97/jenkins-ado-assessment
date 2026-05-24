variable "resource_group_name" {
  description = "Resource group for all networking resources."
  type        = string
}

variable "location" {
  description = "Azure region for networking resources."
  type        = string
}

variable "virtual_network_name" {
  description = "Name of the virtual network."
  type        = string
}

variable "virtual_network_address_space" {
  description = "Address space for the virtual network (e.g. 10.0.0.0/16)."
  type        = list(string)
}

variable "tags" {
  description = "Environment tag applied to all networking resources."
  type        = string
}

# ── Subnet names and address prefixes ─────────────────────────────────────────

variable "firewall_subnet_address_prefixes" {
  description = "Address prefix for AzureFirewallSubnet — must be at least /26."
  type        = list(string)
}

variable "app_gateway_subnet_name" {
  description = "Name of the Application Gateway subnet."
  type        = string
}

variable "app_gateway_subnet_address_prefixes" {
  description = "Address prefixes for the Application Gateway subnet."
  type        = list(string)
}

variable "app_service_subnet_name" {
  description = "Name of the App Service integration subnet."
  type        = string
}

variable "app_service_subnet_address_prefixes" {
  description = "Address prefixes for the App Service subnet."
  type        = list(string)
}

variable "agent_subnet_name" {
  description = "Name of the self-hosted ADO agent subnet."
  type        = string
}

variable "agent_subnet_address_prefixes" {
  description = "Address prefixes for the agent subnet."
  type        = list(string)
}

variable "private_endpoint_subnet_name" {
  description = "Name of the private endpoint subnet."
  type        = string
}

variable "private_endpoint_subnet_address_prefixes" {
  description = "Address prefixes for the private endpoint subnet."
  type        = list(string)
}
