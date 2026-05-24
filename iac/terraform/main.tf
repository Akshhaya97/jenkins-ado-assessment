
# ── Active resources ──────────────────────────────────────────────────────────

module "resource_group" {
  source              = "./modules/resource_group"
  resource_group_name = var.resource_group_name
}

module "networking" {
  for_each = var.networking
  source   = "./modules/networking"

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location

  virtual_network_name          = each.value.virtual_network_name
  virtual_network_address_space = each.value.virtual_network_address_space

  firewall_subnet_address_prefixes         = each.value.firewall_subnet_address_prefixes
  app_gateway_subnet_name                  = each.value.app_gateway_subnet_name
  app_gateway_subnet_address_prefixes      = each.value.app_gateway_subnet_address_prefixes
  app_service_subnet_name                  = each.value.app_service_subnet_name
  app_service_subnet_address_prefixes      = each.value.app_service_subnet_address_prefixes
  agent_subnet_name                        = each.value.agent_subnet_name
  agent_subnet_address_prefixes            = each.value.agent_subnet_address_prefixes
  private_endpoint_subnet_name             = each.value.private_endpoint_subnet_name
  private_endpoint_subnet_address_prefixes = each.value.private_endpoint_subnet_address_prefixes

  tags = each.value.enviroinment_tags
}

# ── Azure Firewall ────────────────────────────────────────────────────────────
module "firewall" {
  source              = "./modules/firewall"
  firewall_name       = var.firewall_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  firewall_subnet_id  = module.networking["primary"].firewall_subnet_id
  tags                = var.tags

  depends_on = [module.networking]
}

# Route table associations — force all subnet traffic through the firewall (UDR)
resource "azurerm_subnet_route_table_association" "app_gateway" {
  subnet_id      = module.networking["primary"].appgw_subnet_id
  route_table_id = module.firewall.route_table_id
}

resource "azurerm_subnet_route_table_association" "app_service" {
  subnet_id      = module.networking["primary"].app_subnet_id
  route_table_id = module.firewall.route_table_id
}

resource "azurerm_subnet_route_table_association" "agent" {
  subnet_id      = module.networking["primary"].agent_subnet_id
  route_table_id = module.firewall.route_table_id
}

resource "azurerm_subnet_route_table_association" "private_endpoint" {
  subnet_id      = module.networking["primary"].private_endpoint_subnet_id
  route_table_id = module.firewall.route_table_id
}

module "identity" {
  source              = "./modules/identity"
  name                = var.identity_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = var.tags
}

data "azurerm_container_registry" "this" {
  name                = var.container_registry_name
  resource_group_name = module.resource_group.name
}

module "app_service_plan" {
  for_each                  = var.app_service_plans
  source                    = "./modules/app_service_plan"
  app_service_plan_name     = each.value.service_plan_name
  resource_group_name       = module.resource_group.name
  location                  = module.resource_group.location
  app_service_plan_sku_name = each.value.sku_name
}

module "mysql" {
  source                 = "./modules/mysql"
  server_name            = var.mysql_server_name
  resource_group_name    = module.resource_group.name
  location               = module.resource_group.location
  administrator_login    = var.mysql_admin_login
  administrator_password = var.mysql_admin_password
  database_name          = var.mysql_database_name
  tags                   = var.tags
}

module "app_service" {
  for_each            = var.app_service
  source              = "./modules/app_service"
  linux_web_app_name  = each.value.linux_web_app_name
  service_plan_name   = each.value.service_plan_name
  service_plan_id     = module.app_service_plan[each.key].app_service_plan_id
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location

  sku_name = "B1"

  #Container Image
  container_image_name            = each.value.container_image_name
  container_registry_login_server = data.azurerm_container_registry.this.login_server
  container_registry_username     = var.container_registry_username
  container_registry_password     = var.container_registry_password

  # VNet integration — outbound traffic routed through app_service subnet
  virtual_network_subnet_id = module.networking["primary"].app_subnet_id

  # MySQL connection passed as app settings
  app_settings = {
    SPRING_PROFILES_ACTIVE = "mysql"
    MYSQL_URL              = module.mysql.jdbc_url
    MYSQL_USER             = var.mysql_admin_login
    MYSQL_PASS             = var.mysql_admin_password
    WEBSITES_PORT          = "8080"
  }

  tags = var.tags

  depends_on = [module.app_service_plan, module.mysql]
}

# ── Application Gateway + WAF ─────────────────────────────────────────────────
# Depends on app_service to get the backend hostname
module "app_gateway" {
  source                = "./modules/app_gateway"
  app_gateway_name      = var.app_gateway_name
  resource_group_name   = module.resource_group.name
  location              = module.resource_group.location
  app_gateway_subnet_id = module.networking["primary"].appgw_subnet_id
  # Use the hostname of the first (primary) App Service as the backend
  app_service_fqdn      = module.app_service["primary"].hostname
  tags                  = var.tags

  depends_on = [module.app_service, module.networking]
}

# ── Private DNS Zones ─────────────────────────────────────────────────────────
# Created for each entry in var.private_dns_zones using for_each
module "private_dns" {
  for_each            = var.private_dns_zones
  source              = "./modules/private_dns"
  zone_name           = each.value
  resource_group_name = module.resource_group.name
  virtual_network_id  = module.networking["primary"].vnet_id
  tags                = var.tags

  depends_on = [module.networking]
}

# ── Private Endpoints ─────────────────────────────────────────────────────────

# ACR private endpoint — removes public access to container registry
module "private_endpoint_acr" {
  source                         = "./modules/private_endpoint"
  name                           = "pe-acr"
  resource_group_name            = module.resource_group.name
  location                       = module.resource_group.location
  subnet_id                      = module.networking["primary"].private_endpoint_subnet_id
  private_connection_resource_id = data.azurerm_container_registry.this.id
  subresource_names              = ["registry"]
  private_dns_zone_ids           = [module.private_dns["acr"].zone_id]
  tags                           = var.tags

  depends_on = [module.private_dns]
}

# MySQL private endpoint — removes public access to database
module "private_endpoint_mysql" {
  source                         = "./modules/private_endpoint"
  name                           = "pe-mysql"
  resource_group_name            = module.resource_group.name
  location                       = module.resource_group.location
  subnet_id                      = module.networking["primary"].private_endpoint_subnet_id
  private_connection_resource_id = module.mysql.server_id
  subresource_names              = ["mysqlServer"]
  private_dns_zone_ids           = [module.private_dns["mysql"].zone_id]
  tags                           = var.tags

  depends_on = [module.mysql, module.private_dns]
}

