resource "azurerm_key_vault_access_policy" "kv_policy" {
  count = var.cmk_enabled && var.use_access_policy ? 1 : 0

  key_vault_id = var.key_vault_id
  object_id    = azurerm_synapse_workspace.this.identity[0].principal_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  key_permissions = [
    "Get",
    "WrapKey",
    "UnwrapKey"
  ]

  depends_on = [azurerm_synapse_workspace.this, time_sleep.wait_for_resources]
}

resource "azurerm_role_assignment" "kv_crypto_user" {
  count = var.cmk_enabled && !var.use_access_policy ? 1 : 0

  principal_id         = azurerm_synapse_workspace.this.identity[0].principal_id
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Crypto User"

  depends_on = [azurerm_synapse_workspace.this, time_sleep.wait_for_resources]
}
