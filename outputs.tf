output "name" {
  description = "The name of the Synapse Workspace."
  value       = azurerm_synapse_workspace.this.name
}

output "resource_id" {
  description = "The resource ID of the Synapse Workspace."
  value       = azurerm_synapse_workspace.this.id
}

output "synapse_workspace_identity_principal_id" {
  description = "The principal id of the workspace identity (system assigned). Nullable if identity not enabled."
  value       = try(azurerm_synapse_workspace.this.identity[0].principal_id, null)
}

output "synapse_workspace_location" {
  description = "The location/region of the Synapse Workspace."
  value       = azurerm_synapse_workspace.this.location
}

output "synapse_workspace_managed_resource_group_name" {
  description = "The managed resource group name for the Synapse Workspace (if any)."
  value       = azurerm_synapse_workspace.this.managed_resource_group_name
}
