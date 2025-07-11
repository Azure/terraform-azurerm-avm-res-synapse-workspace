# TODO: insert resources here.
data "azurerm_resource_group" "parent" {
  name = var.resource_group_name
}

data "azurerm_client_config" "current" {}

resource "random_password" "sql_admin_password" {
  length  = 16
  special = true
}

resource "time_sleep" "wait_for_resources" {
  create_duration = "60s"
}

# Synapse module resource
resource "azurerm_synapse_workspace" "this" {
  location                             = coalesce(var.location, local.resource_group_location)
  name                                 = var.name # calling code must supply the name
  resource_group_name                  = var.resource_group_name
  storage_data_lake_gen2_filesystem_id = var.storage_data_lake_gen2_filesystem_id
  azuread_authentication_only          = var.azuread_authentication_only
  compute_subnet_id                    = var.compute_subnet_id
  data_exfiltration_protection_enabled = var.data_exfiltration_protection_enabled
  linking_allowed_for_aad_tenant_ids   = var.linking_allowed_for_aad_tenant_ids
  managed_resource_group_name          = var.managed_resource_group_name
  managed_virtual_network_enabled      = var.managed_virtual_network_enabled
  public_network_access_enabled        = var.public_network_access_enabled
  purview_id                           = var.purview_id
  sql_administrator_login              = var.sql_administrator_login
  sql_administrator_login_password = (
    var.sql_administrator_login_password != "" ? var.sql_administrator_login_password :
    (var.cmk_enabled && var.cmk_key_versionless_id != null ? null : random_password.sql_admin_password.result)
  )
  sql_identity_control_enabled = var.sql_identity_control_enabled
  tags                         = var.tags

  dynamic "azure_devops_repo" {
    for_each = var.azure_devops_repo != null ? [var.azure_devops_repo] : []

    content {
      account_name    = azure_devops_repo.value.account_name
      branch_name     = azure_devops_repo.value.branch_name
      project_name    = azure_devops_repo.value.project_name
      repository_name = azure_devops_repo.value.repository_name
      root_folder     = azure_devops_repo.value.root_folder
      # Optional fields
      last_commit_id = try(azure_devops_repo.value.last_commit_id, null)
      tenant_id      = try(azure_devops_repo.value.tenant_id, null)
    }
  }
  dynamic "customer_managed_key" {
    for_each = var.cmk_enabled ? [1] : []

    content {
      key_versionless_id        = var.cmk_key_versionless_id
      key_name                  = try(var.cmk_key_name, null)
      user_assigned_identity_id = try(var.cmk_user_assigned_identity_id, null)
    }
  }
  dynamic "github_repo" {
    for_each = var.github_repo != null ? [var.github_repo] : []

    content {
      account_name    = github_repo.value.account_name
      branch_name     = github_repo.value.branch_name
      repository_name = github_repo.value.repository_name
      root_folder     = github_repo.value.root_folder
      git_url         = try(github_repo.value.git_url, null)
      # Optional fields
      last_commit_id = try(github_repo.value.last_commit_id, null)
    }
  }
  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []

    content {
      type         = var.identity_type
      identity_ids = try(var.identity_ids, null)
    }
  }
}

resource "azurerm_synapse_workspace_key" "example" {
  count = var.cmk_enabled ? 1 : 0

  active                              = true
  customer_managed_key_name           = coalesce(var.cmk_key_name, "synk-${var.name}")
  synapse_workspace_id                = azurerm_synapse_workspace.this.id
  customer_managed_key_versionless_id = var.cmk_key_versionless_id

  depends_on = [azurerm_key_vault_access_policy.kv_policy, azurerm_role_assignment.kv_crypto_user, time_sleep.wait_for_resources]
}

resource "azurerm_synapse_workspace_aad_admin" "example" {
  count = var.cmk_enabled ? 1 : 0

  login                = "AzureAD Admin"
  object_id            = var.aad_admin_obj_id
  synapse_workspace_id = azurerm_synapse_workspace.this.id
  tenant_id            = data.azurerm_client_config.current.tenant_id

  depends_on = [azurerm_synapse_workspace_key.example]
}

# required AVM resources interfaces
resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = azurerm_synapse_workspace.this.id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azurerm_synapse_workspace.this.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}

# resource "azurerm_role_assignment" "synapse_blob_contributor" {
#   principal_id         = azurerm_synapse_workspace.this.identity[0].principal_id
#   scope                = azurerm_storage_account.adls.id
#   role_definition_name = "Storage Blob Data Contributor"

#   depends_on = [
#     azurerm_synapse_workspace.this,
#     azurerm_storage_account.adls
#   ]
# }

