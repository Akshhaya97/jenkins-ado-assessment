variable "subscription_id" {
  description = "Azure subscription ID used by Terraform."
  type        = string
}

########################MySQL Variables########################
variable "mysql_server_name" {
  description = "Name of the Azure MySQL Flexible Server."
  type        = string
}

variable "mysql_admin_login" {
  description = "Administrator username for the MySQL server."
  type        = string
}

variable "mysql_admin_password" {
  description = "Administrator password for the MySQL server."
  type        = string
  sensitive   = true
}

variable "mysql_database_name" {
  description = "Name of the database to create."
  type        = string
  default     = "petclinic"
}
###############################################################

# variable "tenant_id" {
#   description = "Azure tenant ID for Key Vault and identity bindings."
#   type        = string
# }

variable "resource_group_name" {
  description = "Existing Azure resource group that will host the workload resources."
  type        = string
}

variable "location" {
  description = "Azure region for the deployment."
  type        = string
}

# variable "environment_name" {
#   description = "Short environment name such as dev, test, or prod."
#   type        = string
#   default     = "dev"
# }

# variable "workload_name" {
#   description = "Base workload name used in resource naming."
#   type        = string
#   default     = "petclinic"
# }

# variable "container_image_name" {
#   description = "Container image name including tag, for example petclinic:latest."
#   type        = string
#   default     = "petclinic:latest"
# }

# variable "app_service_sku_name" {
#   description = "SKU for the Linux App Service plan."
#   type        = string
#   default     = "B1"
# }

variable "tags" {
  description = "Extra tags to merge into all created resources."
  type        = map(string)
  default     = {}
}

variable "identity_name" {
  description = "Name of the user-assigned managed identity."
  type        = string
}

variable "container_registry_name" {
  description = "Name of the Azure Container Registry (no hyphens, max 50 chars)."
  type        = string
}

variable "container_registry_username" {
  description = "Admin username for the Azure Container Registry."
  type        = string
  sensitive   = true
}

variable "container_registry_password" {
  description = "Admin password for the Azure Container Registry."
  type        = string
  sensitive   = true
}

##################Networking Variables##################

variable "networking" {
  description = "Configuration for networking resources."
  type = map(object({
    virtual_network_name                     = string
    virtual_network_address_space            = list(string)
    # Azure Firewall subnet — name is fixed by Azure, only prefix configurable
    firewall_subnet_address_prefixes         = list(string)
    app_gateway_subnet_name                  = string
    app_gateway_subnet_address_prefixes      = list(string)
    app_service_subnet_name                  = string
    app_service_subnet_address_prefixes      = list(string)
    agent_subnet_name                        = string
    agent_subnet_address_prefixes            = list(string)
    private_endpoint_subnet_name             = string
    private_endpoint_subnet_address_prefixes = list(string)
    enviroinment_tags                        = string
  }))
}

variable "firewall_name" {
  description = "Name of the Azure Firewall."
  type        = string
}

variable "app_gateway_name" {
  description = "Name of the Application Gateway."
  type        = string
}

# Map of logical name to private DNS zone FQDN — used with for_each in root
variable "private_dns_zones" {
  description = "Private DNS zones to create for private endpoint name resolution."
  type        = map(string)
  default = {
    acr   = "privatelink.azurecr.io"
    kv    = "privatelink.vaultcore.azure.net"
    mysql = "privatelink.mysql.database.azure.com"
  }
}

###############################################################

########################App Service Plan Variables########################
variable "app_service_plans" {
  description = "Configuration for App Service Plans and associated Web Apps."
  type = map(object({
    service_plan_name = string
    sku_name          = string
    tags              = string
  }))
}



########################App Service Variables########################
variable "app_service" {
  description = "Configuration for App Services."
  type = map(object({
    linux_web_app_name   = string
    service_plan_name    = string
    container_image_name = string
    tags                 = string
  }))
} 