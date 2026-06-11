# Network Traffic Flow — Azure Architecture

## Architecture Overview

```
CIDR Allocations:
  VNet:               10.0.0.0/16
  AzureFirewallSubnet 10.0.0.0/26
  AppGW Subnet:       10.0.1.0/24
  Web-tier Subnet:    10.0.2.0/24
  Agent Subnet:       10.0.3.0/24
  PE Subnet:          10.0.4.0/24
```

---

## 1. INGRESS — User Browser to App Service

### Step 1: DNS Resolution

```
User types: https://petclinic.contoso.com
    ↓
OS queries Public DNS
    ↓
Azure DNS Public Zone: petclinic.contoso.com → A record → AzFW Public IP
    ↓
Browser opens TCP connection to AzFW Public IP:443
```

**DNS Record Required:**
| Zone | Record | Type | Value |
|------|--------|------|-------|
| `contoso.com` (Public) | `petclinic` | `A` | Azure Firewall Public IP |

---

### Step 2: Azure Firewall — DNAT

```
Packet arrives: dst=AzFW_Public_IP:443
    ↓
AzFW evaluates DNAT Rule Collection:
  Rule: allow-https-inbound
    Source:       *
    Dest:         AzFW Public IP
    Port:         443
    Translated →  10.0.1.4 (AppGW Private IP):443
    ↓
Session tracked (stateful)
    ↓
Packet forwarded to AppGW subnet: dst=10.0.1.4:443
```

**AzFW DNAT Rules:**
| Priority | Name | Source | Dest IP | Dest Port | Translated Address | Translated Port |
|----------|------|--------|---------|-----------|-------------------|-----------------|
| 100 | `allow-https-inbound` | `*` | AzFW Public IP | 443 | `10.0.1.4` | 443 |
| 110 | `allow-http-redirect` | `*` | AzFW Public IP | 80 | `10.0.1.4` | 80 |

---

### Step 3: NSG — AppGW Subnet (10.0.1.0/24)

Packet arrives at AppGW subnet — NSG evaluated before reaching AppGW.

**NSG: `nsg-appgw-sub` — Inbound Rules:**
| Priority | Name | Source | Destination | Port | Protocol | Action |
|----------|------|--------|-------------|------|----------|--------|
| 100 | `allow-azfw-https` | AzFW Public IP | `10.0.1.0/24` | 443 | TCP | **Allow** |
| 110 | `allow-azfw-http` | AzFW Public IP | `10.0.1.0/24` | 80 | TCP | **Allow** |
| 200 | `allow-appgw-mgmt` | `GatewayManager` | `10.0.1.0/24` | 65200-65535 | TCP | **Allow** |
| 210 | `allow-azlb-probe` | `AzureLoadBalancer` | `10.0.1.0/24` | `*` | Any | **Allow** |
| 4096 | `deny-all-inbound` | `*` | `*` | `*` | Any | **Deny** |

**NSG: `nsg-appgw-sub` — Outbound Rules:**
| Priority | Name | Source | Destination | Port | Protocol | Action |
|----------|------|--------|-------------|------|----------|--------|
| 100 | `allow-to-appsvc` | `10.0.1.0/24` | `10.0.2.0/24` | 443, 80 | TCP | **Allow** |
| 4096 | `deny-all-outbound` | `*` | `*` | `*` | Any | **Deny** |

> **Note on `GatewayManager` (ports 65200-65535):** AppGW v2 requires Azure's management plane to reach it on these ports. Without this rule AppGW v2 will be in a failed/degraded state and cannot be provisioned or updated.
>
> **Note on `AzureLoadBalancer`:** AppGW v2 runs on multiple auto-scaled instances internally managed by Azure's platform IP `168.63.129.16`. This rule allows Azure to health-probe those instances.

---

### Step 4: Application Gateway — WAF + TLS Termination + Routing

```
Packet arrives at AppGW (10.0.1.4):443
    ↓
TLS Termination:
  Certificate fetched from Key Vault via Managed Identity
  HTTPS decrypted → plain HTTP visible to WAF
    ↓
WAF Policy (OWASP 3.2) inspects request:
  Checks: SQLi, XSS, path traversal, protocol violations
  ↓ BLOCKED → dropped + logged to Log Analytics
  ↓ CLEAN   → passed to Listener
    ↓
Listener match:
  Protocol: HTTPS  Port: 443  Hostname: petclinic.contoso.com ✓
    ↓
Routing Rule → Backend Pool → HTTP Settings
    ↓
Health Probe confirms App Service is alive (/actuator/health)
    ↓
Request forwarded to App Service: dst=10.0.2.x:443 (or 80)
```

---

### Step 5: NSG — Web-tier Subnet (10.0.2.0/24)

**NSG: `nsg-web-sub` — Inbound Rules:**
| Priority | Name | Source | Destination | Port | Protocol | Action |
|----------|------|--------|-------------|------|----------|--------|
| 100 | `allow-appgw-to-appsvc` | `10.0.1.0/24` | `10.0.2.0/24` | 443, 80 | TCP | **Allow** |
| 200 | `allow-ado-agent-deploy` | `10.0.3.0/24` | `10.0.2.0/24` | 443 | TCP | **Allow** |
| 4096 | `deny-all-inbound` | `*` | `*` | `*` | Any | **Deny** |

**NSG: `nsg-web-sub` — Outbound Rules:**
| Priority | Name | Source | Destination | Port | Protocol | Action |
|----------|------|--------|-------------|------|----------|--------|
| 100 | `allow-to-pe-subnet` | `10.0.2.0/24` | `10.0.4.0/24` | 443, 3306 | TCP | **Allow** |
| 110 | `allow-to-appinsights` | `10.0.2.0/24` | `AzureMonitor` | 443 | TCP | **Allow** |
| 200 | `allow-to-azfw-egress` | `10.0.2.0/24` | AzFW Private IP | `*` | Any | **Allow** |
| 4096 | `deny-all-outbound` | `*` | `*` | `*` | Any | **Deny** |

---

### Step 6: App Service — Backend Connections (DB, Key Vault, ACR)

App Service uses **VNet Integration** to reach Private Endpoints in `10.0.4.0/24`.
The **User-Assigned Managed Identity (MI)** authenticates to all PaaS services — no stored credentials.

---

#### 6a. App Service → Key Vault (secrets/certs at startup)

```
App Service reads App Setting:
  @Microsoft.KeyVault(SecretUri=https://mykv.vault.azure.net/secrets/db-password)
    ↓
DNS query: mykv.vault.azure.net
    ↓
Private DNS Zone: privatelink.vaultcore.azure.net (linked to VNet)
  Resolves → 10.0.4.5 (PE_KV private IP)
    ↓
NSG: nsg-pe-sub allows TCP 443 from 10.0.2.0/24 ✓
    ↓
PE_KV → private link → Key Vault (no public endpoint)
    ↓
MI authenticates via Azure AD (Key Vault Secrets User role)
    ↓
Secret injected as environment variable into container
```

---

#### 6b. App Service → ACR (image pull at container startup)

```
App Service starts container: petclinic:latest
    ↓
DNS query: petclinicspringbootacr.azurecr.io
    ↓
Private DNS Zone: privatelink.azurecr.io (linked to VNet)
  Resolves → 10.0.4.4 (PE_ACR private IP)
    ↓
NSG: nsg-pe-sub allows TCP 443 from 10.0.2.0/24 ✓
    ↓
PE_ACR → private link → ACR (no public endpoint)
    ↓
MI authenticates via Azure AD (AcrPull role)
    ↓
Image layers pulled and container started
```

---

#### 6c. App Service → MySQL (JDBC at runtime)

```
Spring Boot app connects on startup (or per request):
  jdbc:mysql://mydb.mysql.database.azure.com:3306/petclinic
    ↓
DNS query: mydb.mysql.database.azure.com
    ↓
Private DNS Zone: privatelink.mysql.database.azure.com (linked to VNet)
  Resolves → 10.0.4.6 (PE_DB private IP)
    ↓
NSG: nsg-pe-sub allows TCP 3306 from 10.0.2.0/24 ✓
    ↓
PE_DB → private link → MySQL Flexible Server (no public endpoint)
    ↓
Auth: password from Key Vault secret (or AAD-based MI auth)
    ↓
Query executes, result returned to App Service
```

---

### Step 7: NSG — Private Endpoint Subnet (10.0.4.0/24)

**NSG: `nsg-pe-sub` — Inbound Rules:**
| Priority | Name | Source | Destination | Port | Protocol | Action |
|----------|------|--------|-------------|------|----------|--------|
| 100 | `allow-appsvc-to-pe` | `10.0.2.0/24` | `10.0.4.0/24` | 443, 3306 | TCP | **Allow** |
| 110 | `allow-agent-to-pe-acr` | `10.0.3.0/24` | `10.0.4.0/24` | 443 | TCP | **Allow** |
| 4096 | `deny-all-inbound` | `*` | `*` | `*` | Any | **Deny** |

**NSG: `nsg-pe-sub` — Outbound Rules:**
| Priority | Name | Source | Destination | Port | Protocol | Action |
|----------|------|--------|-------------|------|----------|--------|
| 4096 | `deny-all-outbound` | `*` | `*` | `*` | Any | **Deny** |

> Private Endpoints are inbound-only — they receive traffic and forward to PaaS backend. Full outbound deny is safe.

> **Important:** Set `PrivateEndpointNetworkPolicies = Enabled` on the PE subnet to enforce NSG rules on Private Endpoints (GA feature — disabled by default).

---

## 2. EGRESS — App Service Response Back to User Browser

### How the Return Path Works

Azure Firewall and NSGs are **stateful** — they track established connections. Return traffic for an allowed inbound session is **automatically permitted** without explicit egress rules.

```
App Service (10.0.2.x) sends response
    ↓
UDR on Web-tier Subnet: 0.0.0.0/0 → AzFW Private IP (10.0.0.4)
  All egress forced through Azure Firewall
    ↓
Azure Firewall:
  Recognizes packet as RETURN traffic for existing DNAT session
  Stateful tracking: no explicit rule needed
  Applies SNAT: src IP changed from 10.0.2.x → AzFW Public IP
    ↓
Internet
    ↓
User Browser receives response from AzFW Public IP
  (Private IPs are never exposed to the internet)
```

### SNAT Explained

| Hop | Source IP | Destination IP |
|-----|-----------|---------------|
| AppGW → AppSvc | `10.0.1.4` | `10.0.2.x` |
| AppSvc → AzFW (UDR) | `10.0.2.x` | User Public IP |
| AzFW → Internet (SNAT) | **AzFW Public IP** | User Public IP |

The user's browser only ever sees the **Azure Firewall Public IP** — internal IPs are never leaked.

---

## 3. CI/CD EGRESS — ADO Agent Flow

### Agent Subnet NSG

**NSG: `nsg-agent-sub` — Inbound Rules:**
| Priority | Name | Source | Destination | Port | Protocol | Action |
|----------|------|--------|-------------|------|----------|--------|
| 100 | `allow-ado-control-plane` | `AzureDevOps` | `10.0.3.0/24` | 443 | TCP | **Allow** |
| 4096 | `deny-all-inbound` | `*` | `*` | `*` | Any | **Deny** |

**NSG: `nsg-agent-sub` — Outbound Rules:**
| Priority | Name | Source | Destination | Port | Protocol | Action |
|----------|------|--------|-------------|------|----------|--------|
| 100 | `allow-to-pe-acr` | `10.0.3.0/24` | `10.0.4.0/24` | 443 | TCP | **Allow** |
| 110 | `allow-to-appsvc-deploy` | `10.0.3.0/24` | `10.0.2.0/24` | 443 | TCP | **Allow** |
| 200 | `allow-to-azfw-egress` | `10.0.3.0/24` | AzFW Private IP | `*` | Any | **Allow** |
| 4096 | `deny-all-outbound` | `*` | `*` | `*` | Any | **Deny** |

### Agent CI/CD Traffic Flow

```
ADO Pipeline triggers job
    ↓
AzureDevOps service tag → Agent VM (10.0.3.x):443
  NSG: allow-ado-control-plane ✓
    ↓
Agent executes pipeline steps:

  docker build .
    ↓ (local operation — no network needed)

  docker push petclinicspringbootacr.azurecr.io/petclinic:v2
    ↓ DNS → privatelink.azurecr.io → 10.0.4.4
    ↓ NSG nsg-agent-sub: allow-to-pe-acr (port 443) ✓
    ↓ NSG nsg-pe-sub: allow-agent-to-pe-acr ✓
    ↓ PE_ACR → ACR (private link)

  az webapp deploy --name petclinic
    ↓ AppSvc management API → 10.0.2.x:443
    ↓ NSG nsg-agent-sub: allow-to-appsvc-deploy ✓
    ↓ NSG nsg-web-sub: allow-ado-agent-deploy ✓
    ↓ App Service updated

  OS patches / external tools (via AzFW app rules)
    ↓ UDR: 0.0.0.0/0 → AzFW
    ↓ AzFW App Rules: allow *.ubuntu.com, *.microsoft.com ✓
```

---

## 4. UDR Summary (Force Egress Through Azure Firewall)

| Route Table | Associated Subnet | Route | Next Hop |
|-------------|------------------|-------|----------|
| `rt-appgw-sub` | `10.0.1.0/24` | `0.0.0.0/0` | AzFW Private IP (`10.0.0.4`) |
| `rt-web-sub` | `10.0.2.0/24` | `0.0.0.0/0` | AzFW Private IP (`10.0.0.4`) |
| `rt-agent-sub` | `10.0.3.0/24` | `0.0.0.0/0` | AzFW Private IP (`10.0.0.4`) |
| `rt-pe-sub` | `10.0.4.0/24` | `0.0.0.0/0` | AzFW Private IP (`10.0.0.4`) |

> `AzureFirewallSubnet` must **NOT** have a UDR — Azure manages its own routing.

---

## 5. Private DNS Zones Summary

| Zone | Resolves | Private IP (PE) |
|------|----------|-----------------|
| `privatelink.azurecr.io` | `petclinicspringbootacr.azurecr.io` | `10.0.4.4` |
| `privatelink.vaultcore.azure.net` | `mykv.vault.azure.net` | `10.0.4.5` |
| `privatelink.mysql.database.azure.com` | `mydb.mysql.database.azure.com` | `10.0.4.6` |

All zones must be **linked to the VNet** so any resource inside resolves to private IPs.

---

## 6. End-to-End Ingress Flow Summary

```
User Browser
  │  DNS: petclinic.contoso.com → AzFW Public IP
  ▼
Azure Firewall (AzureFirewallSubnet 10.0.0.0/26)
  │  DNAT: Public IP:443 → 10.0.1.4:443
  │  Session tracked (stateful)
  ▼
NSG: nsg-appgw-sub
  │  Inbound allow: AzFW IP → 10.0.1.0/24:443 ✓
  ▼
Application Gateway (AppGW Subnet 10.0.1.0/24)
  │  TLS termination (cert from Key Vault)
  │  WAF OWASP 3.2 inspection
  │  Listener match: petclinic.contoso.com
  │  Route → Backend Pool
  ▼
NSG: nsg-web-sub
  │  Inbound allow: 10.0.1.0/24 → 10.0.2.0/24:443 ✓
  ▼
App Service Container (Web-tier Subnet 10.0.2.0/24)
  │  VNet Integration enabled
  ├──► Key Vault (via PE_KV 10.0.4.5) — secrets at startup
  ├──► ACR (via PE_ACR 10.0.4.4) — image pull at startup
  └──► MySQL (via PE_DB 10.0.4.6) — JDBC queries at runtime
         │
         NSG: nsg-pe-sub
           Inbound allow: 10.0.2.0/24 → 10.0.4.0/24:443,3306 ✓
```

---

## 7. End-to-End Egress Flow Summary

```
App Service (10.0.2.x)
  │  Response packet: src=10.0.2.x dst=User Public IP
  ▼
UDR: 0.0.0.0/0 → AzFW Private IP (10.0.0.4)
  ▼
Azure Firewall
  │  Stateful: return traffic for existing session → auto-allow
  │  SNAT: src IP replaced with AzFW Public IP
  ▼
Internet
  ▼
User Browser
  └  Sees response from AzFW Public IP (private IPs never exposed)
```
