# TODO: insert resources here.
data "azurerm_resource_group" "parent" {
  count = var.location == null ? 1 : 0

  name = var.resource_group_name
}

resource "random_password" "synapse_sql_admin_password" {
  length  = 16
  special = true
}

# Synapse module resource
resource "azurerm_synapse_workspace" "this" {
  location = coalesce(var.location, local.resource_group_location)
  name     = var.name # calling code must supply the name
  resource_group_name = var.resource_group_name
  storage_data_lake_gen2_filesystem_id = var.storage_data_lake_gen2_filesystem_id
  sql_administrator_login = var.sql_administrator_login
  sql_administrator_login_password = coalesce(var.sql_administrator_login_password, random_password.synapse_sql_admin_password)
  customer_managed_key {
      key_name = var.cmk_enabled ? var.synapse_key_name : null
      key_versionless_id = var.cmk_enabled ? var.key_versionless_id : null
  }
  identity {
    type = var.managed_identities
  }
  tags = var.tags
}

resource "azurerm_synapse_workspace_key" "example" {
  count = var.cmk_enabled ? 1 : 0

  customer_managed_key_versionless_id = var.key_versionless_id
  synapse_workspace_id                = azurerm_synapse_workspace.this.id
  active                              = true
  customer_managed_key_name           = var.synapse_key_name
  depends_on                          = [azurerm_key_vault_access_policy.synapsepolicy]
}

resource "azurerm_synapse_workspace_aad_admin" "example" {
  count = var.cmk_enabled ? 1 : 0

  synapse_workspace_id = azurerm_synapse_workspace.this.id
  login                = "AzureAD Admin"
  object_id            = var.aad_admin_obj_id
  tenant_id            = data.azurerm_client_config.current.tenant_id
  depends_on = [azurerm_synapse_workspace.this]
}


# required AVM resources interfaces
resource "azurerm_management_lock" "this" {
  count = var.lock.kind != "None" ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.name}")
  scope      = azurerm_resource_group.TODO.id # TODO: Replace this dummy resource azurerm_resource_group.TODO with your module resource
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azurerm_resource_group.TODO.id # TODO: Replace this dummy resource azurerm_resource_group.TODO with your module resource
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}
