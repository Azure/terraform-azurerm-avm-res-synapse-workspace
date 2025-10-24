data "azurerm_client_config" "current" {}

resource "time_sleep" "wait_for_resources" {
  create_duration = "60s"
}

resource "azurerm_synapse_workspace" "this" {
  location                             = var.location
  name                                 = var.name
  resource_group_name                  = var.resource_group_name
  storage_data_lake_gen2_filesystem_id = var.storage_data_lake_gen2_filesystem_id
  azuread_authentication_only          = var.entra_id_authentication_only_enabled
  compute_subnet_id                    = var.compute_subnet_id
  data_exfiltration_protection_enabled = var.data_exfiltration_protection_enabled
  linking_allowed_for_aad_tenant_ids   = var.linking_allowed_for_entra_id_tenant_ids
  managed_resource_group_name          = var.managed_resource_group_name
  managed_virtual_network_enabled      = var.managed_virtual_network_enabled
  public_network_access_enabled        = var.public_network_access_enabled
  purview_id                           = var.purview_id
  sql_administrator_login              = var.sql_administrator_login
  sql_administrator_login_password     = var.sql_administrator_login_password
  sql_identity_control_enabled         = var.sql_identity_control_enabled
  tags                                 = var.tags

  dynamic "azure_devops_repo" {
    for_each = var.azure_devops_repository != null ? [var.azure_devops_repository] : []

    content {
      account_name    = azure_devops_repository.value.account_name
      branch_name     = azure_devops_repository.value.branch_name
      project_name    = azure_devops_repository.value.project_name
      repository_name = azure_devops_repository.value.repository_name
      root_folder     = azure_devops_repository.value.root_folder
      last_commit_id  = azure_devops_repository.value.last_commit_id
      tenant_id       = azure_devops_repository.value.tenant_id
    }
  }
  dynamic "customer_managed_key" {
    for_each = var.customer_managed_key != null ? [var.customer_managed_key] : []

    content {
      key_name               = customer_managed_key.value.key_name
      key_vault_resource_id  = customer_managed_key.value.key_vault_resource_id
      key_version            = try(customer_managed_key.value.key_version, null)
      user_assigned_identity = try(customer_managed_key.value.user_assigned_identity, null)
    }
  }
  dynamic "github_repo" {
    for_each = var.github_repository != null ? [var.github_repository] : []

    content {
      account_name    = github_repository.value.account_name
      branch_name     = github_repository.value.branch_name
      repository_name = github_repository.value.repository_name
      root_folder     = github_repository.value.root_folder
      git_url         = github_repository.value.git_url
      last_commit_id  = github_repository.value.last_commit_id
    }
  }
  dynamic "identity" {
    for_each = local.managed_identities.system_assigned_user_assigned

    content {
      type         = identity.value.type
      identity_ids = identity.value.user_assigned_resource_ids
    }
  }
}

# Removed: azurerm_synapse_workspace_key resource, as the AVM interface expects the customer_managed_key block to be handled directly in the main resource.

resource "azurerm_synapse_workspace_aad_admin" "admin" {
  count = var.entra_id_admin_login != null && var.entra_id_admin_object_id != null ? 1 : 0

  login                = var.entra_id_admin_login
  object_id            = var.entra_id_admin_object_id
  synapse_workspace_id = azurerm_synapse_workspace.this.id
  tenant_id            = data.azurerm_client_config.current.tenant_id
}

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
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), "/providers/microsoft.authorization/roledefinitions") ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), "/providers/microsoft.authorization/roledefinitions") ? null : each.value.role_definition_id_or_name
}
