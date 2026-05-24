variable "server_name" {
  description = "Name of the MySQL Flexible Server."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where the MySQL server will be created."
  type        = string
}

variable "location" {
  description = "Azure region for the MySQL server."
  type        = string
}

variable "administrator_login" {
  description = "Administrator username for the MySQL server."
  type        = string
}

variable "administrator_password" {
  description = "Administrator password for the MySQL server."
  type        = string
  sensitive   = true
}

variable "database_name" {
  description = "Name of the database to create on the server."
  type        = string
  default     = "petclinic"
}

variable "sku_name" {
  description = "SKU for the MySQL Flexible Server (e.g. B_Standard_B1ms)."
  type        = string
  default     = "B_Standard_B1ms"
}

variable "tags" {
  description = "Tags to apply to the MySQL resources."
  type        = map(string)
  default     = {}
}
