resource "azurerm_key_vault_access_policy" "kv_policy" {
  count = var.customer_managed_key_enabled && var.use_access_policy ? 1 : 0

  key_vault_id = var.customer_managed_key.key_vault_resource_id
  object_id    = azurerm_synapse_workspace.this.identity[0].principal_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  key_permissions = [
    "Get",
    "WrapKey",
    "UnwrapKey"
  ]
}

resource "time_sleep" "key_vault_access_policy" {
  count = var.customer_managed_key_enabled && var.key_vault_access_policy_wait_duration != "0s" ? 1 : 0

  create_duration = var.key_vault_access_policy_wait_duration
  triggers = {
    key_vault_access_policy_id = try(azurerm_key_vault_access_policy.kv_policy[0].id, null)
    role_assignment_id         = try(azurerm_role_assignment.kv_crypto_user[0].id, null)
  }
}

resource "azurerm_role_assignment" "kv_crypto_user" {
  count = var.customer_managed_key_enabled && !var.use_access_policy ? 1 : 0

  principal_id         = azurerm_synapse_workspace.this.identity[0].principal_id
  scope                = var.customer_managed_key.key_vault_resource_id
  role_definition_name = "Key Vault Crypto User"
}
