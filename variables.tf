variable "location" {
  type        = string
  description = "Azure region where the resource should be deployed.  If null, the location will be inferred from the resource group location."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of the this resource."
}

variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
}

variable "sql_administrator_login_password" {
  type        = string
  description = "The Password associated with the sql_administrator_login for the SQL administrator. If this is not provided customer_managed_key must be provided."
  sensitive   = true
}

variable "storage_data_lake_gen2_filesystem_id" {
  type        = string
  description = "Specifies the ID of storage data lake gen2 filesystem resource. Changing this forces a new resource to be created."
}

variable "azure_devops_repository" {
  type = object({
    account_name    = string
    branch_name     = string
    last_commit_id  = optional(string)
    project_name    = string
    repository_name = string
    root_folder     = string
    tenant_id       = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
Optional configuration for Azure DevOps repository integration.

- `account_name` - (Required) The Azure DevOps account name.
- `branch_name` - (Required) The branch name to use for the repository.
- `last_commit_id` - (Optional) The last commit ID to use.
- `project_name` - (Required) The Azure DevOps project name.
- `repository_name` - (Required) The repository name.
- `root_folder` - (Required) The root folder path in the repository.
- `tenant_id` - (Optional) The tenant ID for the Azure DevOps account.

Example Input:

```terraform
azure_devops_repository = {
  account_name    = "mydevopsaccount"
  branch_name     = "main"
  project_name    = "MyProject"
  repository_name = "synapse-workspace"
  root_folder     = "/synapse"
  tenant_id       = "00000000-0000-0000-0000-000000000000"
}
```
DESCRIPTION
}

variable "compute_subnet_id" {
  type        = string
  default     = null
  description = "The ID of the subnet to use for the compute resources. Changing this forces a new resource to be created."
}

variable "customer_managed_key" {
  type = object({
    key_name           = optional(string, null)
    key_versionless_id = string
    user_assigned_identity = optional(object({
      resource_id = string
    }), null)
  })
  default     = null
  description = <<DESCRIPTION
Controls the Customer Managed Key configuration for this resource. The following properties can be specified:
- `key_name` - (Optional) The name of the key in the Key Vault.
- `key_versionless_id` - (Required) The version of the key. If not specified, the latest version will be used.
- `user_assigned_identity` - (Optional) An object with `resource_id` for the User Assigned Managed Identity to access the key.
DESCRIPTION
}

variable "customer_managed_key_enabled" {
  type        = bool
  default     = false
  description = "Controls whether a customer managed key is enabled for the Synapse workspace. If true, the customer_managed_key object must be provided. If false, no customer managed key will be configured."
}

variable "data_exfiltration_protection_enabled" {
  type        = bool
  default     = false
  description = "Is data exfiltration protection enabled in this workspace? If set to true, managed_virtual_network_enabled must also be set to true. Changing this forces a new resource to be created."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "entra_id_admin_login" {
  type        = string
  default     = "AzureAD Admin"
  description = "The login name for the Synapse workspace Entra ID admin."
}

variable "entra_id_admin_object_id" {
  type        = string
  default     = ""
  description = "The Object ID of Entra ID group to be added as an admin"
}

variable "entra_id_authentication_only_enabled" {
  type        = bool
  default     = false
  description = "Is Entra ID Authentication the only way to authenticate with resources inside this synapse Workspace."
}

variable "github_repository" {
  type = object({
    account_name    = string
    branch_name     = string
    repository_name = string
    root_folder     = string
    last_commit_id  = optional(string)
    git_url         = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
Optional configuration for GitHub repository integration.

- `account_name` - (Required) The GitHub account or organization name.
- `branch_name` - (Required) The branch name to use for the repository.
- `repository_name` - (Required) The repository name.
- `root_folder` - (Required) The root folder path in the repository.
- `last_commit_id` - (Optional) The last commit ID to use.
- `git_url` - (Optional) The Git URL for the repository.

Example Input:

```terraform
github_repository = {
  account_name    = "myorganization"
  branch_name     = "main"
  repository_name = "synapse-workspace"
  root_folder     = "/synapse"
  git_url         = "https://github.com/myorganization/synapse-workspace.git"
}
```
DESCRIPTION
}

variable "linking_allowed_for_entra_id_tenant_ids" {
  type        = list(string)
  default     = []
  description = "A set of Entra ID tenant IDs that are allowed to link to this workspace. If not specified, all tenants are allowed."
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `"CanNotDelete"` and `"ReadOnly"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.

Example Input:

```terraform
lock = {
  kind = "CanNotDelete"
  name = "synapse-workspace-lock"
}
```
DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "Lock kind must be either `\"CanNotDelete\"` or `\"ReadOnly\"`."
  }
}

variable "managed_identities" {
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Controls the Managed Identity configuration on this resource. The following properties can be specified:
- `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
- `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.
DESCRIPTION
  nullable    = false
}

variable "managed_resource_group_name" {
  type        = string
  default     = null
  description = "Workspace managed resource group. Changing this forces a new resource to be created."
}

variable "managed_virtual_network_enabled" {
  type        = bool
  default     = false
  description = "Is Virtual Network enabled for all computes in this workspace? Changing this forces a new resource to be created."
}

variable "public_network_access_enabled" {
  type        = bool
  default     = false
  description = "Whether public network access is enabled for the workspace. Defaults to true."
}

variable "purview_id" {
  type        = string
  default     = null
  description = "The ID of the Purview account to link to the Synapse workspace. If not specified, no link will be created."
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of role assignments to create on the Synapse Workspace. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - (Optional) The description of the role assignment.
- `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - (Optional) The condition which will be used to scope the role assignment.
- `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
- `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
- `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.

Example Input:

```terraform
role_assignments = {
  "contributor" = {
    role_definition_id_or_name = "Contributor"
    principal_id               = "00000000-0000-0000-0000-000000000000"
    description                = "Contributor access for Synapse workspace"
  }
  "reader" = {
    role_definition_id_or_name = "Reader"
    principal_id               = "11111111-1111-1111-1111-111111111111"
    principal_type             = "User"
  }
}
```
DESCRIPTION
  nullable    = false
}

variable "sql_administrator_login" {
  type        = string
  default     = "SQLAdmin"
  description = "Specifies The login name of the SQL administrator. Changing this forces a new resource to be created. If this is not provided customer_managed_key must be provided. "
}

variable "sql_identity_control_enabled" {
  type        = bool
  default     = false
  description = "Are pipelines (running as workspace's system assigned identity) allowed to access SQL pools?"
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) A mapping of tags to assign to the Container App."
}
