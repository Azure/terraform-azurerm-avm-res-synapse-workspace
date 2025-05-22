resource "azurerm_key_vault_access_policy" "synapsepolicy" {
  count        = var.cmk_enabled && var.use_access_policy ? 1 : 0
  key_vault_id = var.key_vault_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_synapse_workspace.this.identity[0].principal_id

  key_permissions = [
    "Get",
    "WrapKey",
    "UnwrapKey"
  ]
}

resource "azurerm_role_assignment" "example" {
  count                = var.cmk_enabled && var.use_access_policy ? 1 : 0
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Crypto Officer"
  principal_id         = azurerm_synapse_workspace.this.identity[0].principal_id
}