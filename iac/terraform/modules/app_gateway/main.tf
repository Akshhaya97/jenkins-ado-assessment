# Public IP for Application Gateway — Standard SKU required for WAF v2
resource "azurerm_public_ip" "app_gateway" {
  name                = "${var.app_gateway_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# WAF Policy — OWASP 3.2 ruleset in Prevention mode
resource "azurerm_web_application_firewall_policy" "this" {
  name                = "${var.app_gateway_name}-waf-policy"
  location            = var.location
  resource_group_name = var.resource_group_name

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }

  tags = var.tags
}

# Application Gateway v2 — terminates TLS and routes traffic to App Service backend
# Note: switch to HTTPS listener with an SSL certificate for production
resource "azurerm_application_gateway" "this" {
  name                = var.app_gateway_name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 1
  }

  firewall_policy_id = azurerm_web_application_firewall_policy.this.id

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = var.app_gateway_subnet_id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "public-frontend"
    public_ip_address_id = azurerm_public_ip.app_gateway.id
  }

  # Backend points to the App Service hostname
  backend_address_pool {
    name  = "app-service-backend"
    fqdns = [var.app_service_fqdn]
  }

  # Health probe for App Service - checks if backend is healthy
  probe {
    name                                      = "app-service-health-probe"
    protocol                                  = "Https"
    path                                      = "/"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true
    match {
      status_code = ["200-399"]
    }
  }

  backend_http_settings {
    name                                = "http-backend-settings"
    cookie_based_affinity               = "Disabled"
    port                                = 443
    protocol                            = "Https"
    request_timeout                     = 60
    pick_host_name_from_backend_address = true
    probe_name                          = "app-service-health-probe"
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "public-frontend"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "http-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "app-service-backend"
    backend_http_settings_name = "http-backend-settings"
    priority                   = 100
  }

  tags = var.tags
}
