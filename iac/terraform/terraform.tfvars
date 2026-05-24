# ── Identity ──────────────────────────────────────────────────────────────────
subscription_id         = "a2b28c85-1948-4263-90ca-bade2bac4df4"
identity_name           = "petclinic-dev-id"
container_registry_name = "petclinispring"

# ── MySQL ─────────────────────────────────────────────────────────────────────
mysql_server_name   = "petclinic-dev-mysql"
mysql_admin_login   = "petclinicadmin"
mysql_database_name = "petclinic"
# mysql_admin_password — pass via CLI: -var="mysql_admin_password=<your-password>"

# ── Resource Group ────────────────────────────────────────────────────────────
resource_group_name = "kml_rg_main-130ce789855e44d9"

# ── Common ────────────────────────────────────────────────────────────────────
location = "eastus"
# workload_name    = "petclinic"

# ── Networking ────────────────────────────────────────────────────────────────
networking = {
  primary = {
    virtual_network_name          = "petclinic-dev-vnet"
    virtual_network_address_space = ["10.0.0.0/16"]

    # Azure Firewall requires /26 minimum and subnet named exactly AzureFirewallSubnet
    firewall_subnet_address_prefixes = ["10.0.0.0/26"]

    app_gateway_subnet_name             = "petclinic-dev-appgw-snet"
    app_gateway_subnet_address_prefixes = ["10.0.1.0/24"]

    app_service_subnet_name             = "petclinic-dev-app-snet"
    app_service_subnet_address_prefixes = ["10.0.2.0/24"]

    agent_subnet_name             = "petclinic-dev-agent-snet"
    agent_subnet_address_prefixes = ["10.0.3.0/24"]

    private_endpoint_subnet_name             = "petclinic-dev-pe-snet"
    private_endpoint_subnet_address_prefixes = ["10.0.4.0/24"]

    enviroinment_tags = "dev"
  }
}

# ── Firewall + App Gateway ────────────────────────────────────────────────────
firewall_name    = "petclinic-dev-fw"
app_gateway_name = "petclinic-dev-appgw"

# ── App Service Plan ───────────────────────────────────────────────────────────────
app_service_plans = {
  primary = {
    service_plan_name = "petclinic-dev-service-plan"
    sku_name          = "B1"
    tags              = "dev"
  }
}

# ── App Service ───────────────────────────────────────────────────────────────
app_service = {
  primary = {
    linux_web_app_name   = "petclinic-dev-linux-web-app"
    service_plan_name    = "petclinic-dev-service-plan"
    container_image_name = "petclinic:latest"
    tags                 = "dev"
  }
}
