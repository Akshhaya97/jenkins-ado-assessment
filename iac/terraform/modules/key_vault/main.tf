resource "azurerm_key_vault" "this" {
  name                            = var.name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  tenant_id                       = var.tenant_id
  sku_name                        = var.sku_name
  enabled_for_template_deployment = var.enabled_for_template_deployment
  purge_protection_enabled        = var.purge_protection_enabled
  soft_delete_retention_days      = var.soft_delete_retention_days
  tags                            = var.tags
}

resource "azurerm_key_vault_access_policy" "this" {
  for_each = var.access_policies

  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = each.value.tenant_id
  object_id    = each.value.object_id

  secret_permissions = each.value.secret_permissions
}