locals {
  managed_identities = {
    system_assigned_user_assigned = (
      (try(var.managed_identities.system_assigned, false)) || length(try(var.managed_identities.user_assigned_resource_ids, [])) > 0
    ) ? {
      this = {
        type = (
          try(var.managed_identities.system_assigned, false) && length(try(var.managed_identities.user_assigned_resource_ids, [])) > 0
        ) ? "SystemAssigned, UserAssigned" : length(try(var.managed_identities.user_assigned_resource_ids, [])) > 0 ? "UserAssigned" : "SystemAssigned"
        user_assigned_resource_ids = try(var.managed_identities.user_assigned_resource_ids, [])
      }
    } : {}
    system_assigned = try(var.managed_identities.system_assigned, false) ? {
      this = {
        type = "SystemAssigned"
      }
    } : {}
    user_assigned = length(try(var.managed_identities.user_assigned_resource_ids, [])) > 0 ? {
      this = {
        type = "UserAssigned"
        user_assigned_resource_ids = try(var.managed_identities.user_assigned_resource_ids, [])
      }
    } : {}
  }
}
