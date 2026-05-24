# ── Virtual Network ───────────────────────────────────────────────────────────
resource "azurerm_virtual_network" "petclinic_vnet" {
  name                = var.virtual_network_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.virtual_network_address_space

  tags = {
    environment = var.tags
  }
}

# ── Subnets ───────────────────────────────────────────────────────────────────

# Azure Firewall — subnet name must be exactly "AzureFirewallSubnet" (min /26)
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.petclinic_vnet.name
  address_prefixes     = var.firewall_subnet_address_prefixes
}

# Application Gateway — WAF v2 requires its own dedicated subnet
resource "azurerm_subnet" "app_gateway" {
  name                 = var.app_gateway_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.petclinic_vnet.name
  address_prefixes     = var.app_gateway_subnet_address_prefixes
}

# App Service — delegation required for outbound VNet integration
resource "azurerm_subnet" "app_service" {
  name                 = var.app_service_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.petclinic_vnet.name
  address_prefixes     = var.app_service_subnet_address_prefixes

  delegation {
    name = "delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"
      ]
    }
  }
}

# Self-hosted ADO build agent
resource "azurerm_subnet" "agent" {
  name                 = var.agent_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.petclinic_vnet.name
  address_prefixes     = var.agent_subnet_address_prefixes
}

# Private endpoints for ACR, Key Vault, and MySQL
resource "azurerm_subnet" "private_endpoint" {
  name                 = var.private_endpoint_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.petclinic_vnet.name
  address_prefixes     = var.private_endpoint_subnet_address_prefixes
}

# ── NSGs ──────────────────────────────────────────────────────────────────────

# AppGW NSG — allow HTTPS inbound + Azure-required management ports (65200-65535)
resource "azurerm_network_security_group" "app_gateway" {
  name                = "${var.app_gateway_subnet_name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "allow-https-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-http-inbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # Azure requires this port range open for AppGW health and management traffic
  security_rule {
    name                       = "allow-appgw-management"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  tags = { environment = var.tags }
}

resource "azurerm_subnet_network_security_group_association" "app_gateway" {
  subnet_id                 = azurerm_subnet.app_gateway.id
  network_security_group_id = azurerm_network_security_group.app_gateway.id
}

# App Service NSG — only allow inbound from Application Gateway
resource "azurerm_network_security_group" "app_service" {
  name                = "${var.app_service_subnet_name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "allow-from-appgw"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.app_gateway_subnet_address_prefixes[0]
    destination_address_prefix = "*"
  }

  tags = { environment = var.tags }
}

resource "azurerm_subnet_network_security_group_association" "app_service" {
  subnet_id                 = azurerm_subnet.app_service.id
  network_security_group_id = azurerm_network_security_group.app_service.id
}

# Agent NSG — deny unexpected inbound; agent only needs outbound
resource "azurerm_network_security_group" "agent" {
  name                = "${var.agent_subnet_name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "deny-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  tags = { environment = var.tags }
}

resource "azurerm_subnet_network_security_group_association" "agent" {
  subnet_id                 = azurerm_subnet.agent.id
  network_security_group_id = azurerm_network_security_group.agent.id
}

# Private Endpoint NSG — deny all inbound from Internet
resource "azurerm_network_security_group" "private_endpoint" {
  name                = "${var.private_endpoint_subnet_name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "deny-internet-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  tags = { environment = var.tags }
}

resource "azurerm_subnet_network_security_group_association" "private_endpoint" {
  subnet_id                 = azurerm_subnet.private_endpoint.id
  network_security_group_id = azurerm_network_security_group.private_endpoint.id
}
