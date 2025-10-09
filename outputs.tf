# output "private_endpoints" {
#   description = "A map of private endpoints. The map key is the supplied input to var.private_endpoints. The map value is the entire azurerm_private_endpoint resource."
#   value       = azurerm_private_endpoint.this
# }

# Module owners should include the full resource via a 'resource' output
# https://azure.github.io/Azure-Verified-Modules/specs/terraform/#id-tffr2---category-outputs---additional-terraform-outputs
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

output "synapse_workspace_name" {
  description = "The name of the Synapse Workspace."
  value       = azurerm_synapse_workspace.this.name
}
