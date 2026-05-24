variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "sku_name" {
  type    = string
  default = "standard"
}

variable "enabled_for_template_deployment" {
  type    = bool
  default = true
}

variable "purge_protection_enabled" {
  type    = bool
  default = false
}

variable "soft_delete_retention_days" {
  type    = number
  default = 7
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "access_policies" {
  type = map(object({
    tenant_id          = string
    object_id          = string
    secret_permissions = list(string)
  }))
  default = {}
}