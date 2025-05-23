<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-avm-template

This is a template repo for Terraform Azure Verified Modules.

Things to do:

1. Set up a GitHub repo environment called `test`.
1. Configure environment protection rule to ensure that approval is required before deploying to this environment.
1. Create a user-assigned managed identity in your test subscription.
1. Create a role assignment for the managed identity on your test subscription, use the minimum required role.
1. Configure federated identity credentials on the user assigned managed identity. Use the GitHub environment.
1. Search and update TODOs within the code and remove the TODO comments once complete.

> [!IMPORTANT]
> As the overall AVM framework is not GA (generally available) yet - the CI framework and test automation is not fully functional and implemented across all supported languages yet - breaking changes are expected, and additional customer feedback is yet to be gathered and incorporated. Hence, modules **MUST NOT** be published at version `1.0.0` or higher at this time.
>
> All module **MUST** be published as a pre-release version (e.g., `0.1.0`, `0.1.1`, `0.2.0`, etc.) until the AVM framework becomes GA.
>
> However, it is important to note that this **DOES NOT** mean that the modules cannot be consumed and utilized. They **CAN** be leveraged in all types of environments (dev, test, prod etc.). Consumers can treat them just like any other IaC module and raise issues or feature requests against them as they learn from the usage of the module. Consumers should also read the release notes for each version, if considering updating to a more recent version of a module to see if there are any considerations or breaking changes etc.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.5.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 4.28.0, < 5.0.0)

- <a name="requirement_modtm"></a> [modtm](#requirement\_modtm) (~> 0.3)

- <a name="requirement_random"></a> [random](#requirement\_random) (>= 3.6.0, < 4.0)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (>= 4.28.0, < 5.0.0)

- <a name="provider_modtm"></a> [modtm](#provider\_modtm) (~> 0.3)

- <a name="provider_random"></a> [random](#provider\_random) (>= 3.6.0, < 4.0)

## Resources

The following resources are used by this module:

- [azurerm_key_vault_access_policy.synapsepolicy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_access_policy) (resource)
- [azurerm_management_lock.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) (resource)
- [azurerm_role_assignment.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_synapse_workspace.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/synapse_workspace) (resource)
- [azurerm_synapse_workspace_aad_admin.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/synapse_workspace_aad_admin) (resource)
- [azurerm_synapse_workspace_key.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/synapse_workspace_key) (resource)
- [modtm_telemetry.telemetry](https://registry.terraform.io/providers/Azure/modtm/latest/docs/resources/telemetry) (resource)
- [random_password.synapse_sql_admin_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) (resource)
- [random_uuid.telemetry](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) (resource)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [azurerm_client_config.telemetry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [azurerm_resource_group.parent](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) (data source)
- [modtm_module_source.telemetry](https://registry.terraform.io/providers/Azure/modtm/latest/docs/data-sources/module_source) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_name"></a> [name](#input\_name)

Description: The name of the this resource.

Type: `string`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: The resource group where the resources will be deployed.

Type: `string`

### <a name="input_storage_data_lake_gen2_filesystem_id"></a> [storage\_data\_lake\_gen2\_filesystem\_id](#input\_storage\_data\_lake\_gen2\_filesystem\_id)

Description: Specifies the ID of storage data lake gen2 filesystem resource. Changing this forces a new resource to be created.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_aad_admin_obj_id"></a> [aad\_admin\_obj\_id](#input\_aad\_admin\_obj\_id)

Description: The Object ID of AAD group to be added as an admin

Type: `string`

Default: `""`

### <a name="input_azure_devops_repo"></a> [azure\_devops\_repo](#input\_azure\_devops\_repo)

Description: Optional map for Azure DevOps repository configuration.

Type:

```hcl
object({
    account_name    = string
    branch_name     = string
    last_commit_id  = optional(string)
    project_name    = string
    repository_name = string
    root_folder     = string
    tenant_id       = optional(string)
  })
```

Default: `null`

### <a name="input_azuread_authentication_only"></a> [azuread\_authentication\_only](#input\_azuread\_authentication\_only)

Description: Is Azure Active Directory Authentication the only way to authenticate with resources inside this synapse Workspace.

Type: `bool`

Default: `false`

### <a name="input_cmk_enabled"></a> [cmk\_enabled](#input\_cmk\_enabled)

Description: Flag to enable the customer\_managed\_key block.

Type: `bool`

Default: `false`

### <a name="input_cmk_key_name"></a> [cmk\_key\_name](#input\_cmk\_key\_name)

Description: An identifier for the key. Defaults to 'cmk' if not specified.

Type: `string`

Default: `null`

### <a name="input_cmk_key_versionless_id"></a> [cmk\_key\_versionless\_id](#input\_cmk\_key\_versionless\_id)

Description: The Azure Key Vault Key Versionless ID to be used as the Customer Managed Key (CMK) for double encryption.

Type: `string`

Default: `null`

### <a name="input_cmk_user_assigned_identity_id"></a> [cmk\_user\_assigned\_identity\_id](#input\_cmk\_user\_assigned\_identity\_id)

Description: The User Assigned Identity ID to be used for accessing the Customer Managed Key for encryption.

Type: `string`

Default: `null`

### <a name="input_compute_subnet_id"></a> [compute\_subnet\_id](#input\_compute\_subnet\_id)

Description: The ID of the subnet to use for the compute resources. Changing this forces a new resource to be created.

Type: `string`

Default: `null`

### <a name="input_data_exfiltration_protection_enabled"></a> [data\_exfiltration\_protection\_enabled](#input\_data\_exfiltration\_protection\_enabled)

Description: Is data exfiltration protection enabled in this workspace? If set to true, managed\_virtual\_network\_enabled must also be set to true. Changing this forces a new resource to be created.

Type: `bool`

Default: `false`

### <a name="input_diagnostic_settings"></a> [diagnostic\_settings](#input\_diagnostic\_settings)

Description: A map of diagnostic settings to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
- `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
- `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
- `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
- `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
- `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
- `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
- `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
- `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
- `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.

Type:

```hcl
map(object({
    name                                     = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_github_repo"></a> [github\_repo](#input\_github\_repo)

Description: Optional block for GitHub repository configuration.

Type:

```hcl
object({
    account_name    = string
    branch_name     = string
    repository_name = string
    root_folder     = string
    last_commit_id  = optional(string)
    git_url         = optional(string)
  })
```

Default: `null`

### <a name="input_identity_ids"></a> [identity\_ids](#input\_identity\_ids)

Description: Specifies a list of User Assigned Managed Identity IDs to be assigned to this Synapse Workspace. This is required when type is set to UserAssigned or SystemAssigned, UserAssigned.

Type: `list(string)`

Default: `null`

### <a name="input_identity_type"></a> [identity\_type](#input\_identity\_type)

Description: Specifies the type of Managed Service Identity that should be associated with this Synapse Workspace. Possible values: SystemAssigned, UserAssigned, SystemAssigned, UserAssigned.

Type: `string`

Default: `"SystemAssigned"`

### <a name="input_key_vault_id"></a> [key\_vault\_id](#input\_key\_vault\_id)

Description: The ID of the Key Vault

Type: `string`

Default: `""`

### <a name="input_linking_allowed_for_aad_tenant_ids"></a> [linking\_allowed\_for\_aad\_tenant\_ids](#input\_linking\_allowed\_for\_aad\_tenant\_ids)

Description: A set of AAD tenant IDs that are allowed to link to this workspace. If not specified, all tenants are allowed.

Type: `list(string)`

Default: `[]`

### <a name="input_location"></a> [location](#input\_location)

Description: Azure region where the resource should be deployed.  If null, the location will be inferred from the resource group location.

Type: `string`

Default: `null`

### <a name="input_lock"></a> [lock](#input\_lock)

Description: The lock level to apply. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`.

Type:

```hcl
object({
    name = optional(string, null)
    kind = optional(string, "None")
  })
```

Default: `{}`

### <a name="input_managed_resource_group_name"></a> [managed\_resource\_group\_name](#input\_managed\_resource\_group\_name)

Description: Workspace managed resource group. Changing this forces a new resource to be created.

Type: `string`

Default: `null`

### <a name="input_managed_virtual_network_enabled"></a> [managed\_virtual\_network\_enabled](#input\_managed\_virtual\_network\_enabled)

Description: Is Virtual Network enabled for all computes in this workspace? Changing this forces a new resource to be created.

Type: `bool`

Default: `false`

### <a name="input_private_endpoints"></a> [private\_endpoints](#input\_private\_endpoints)

Description: A map of private endpoints to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the private endpoint. One will be generated if not set.
- `role_assignments` - (Optional) A map of role assignments to create on the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time. See `var.role_assignments` for more information.
- `lock` - (Optional) The lock level to apply to the private endpoint. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`.
- `tags` - (Optional) A mapping of tags to assign to the private endpoint.
- `subnet_resource_id` - The resource ID of the subnet to deploy the private endpoint in.
- `private_dns_zone_group_name` - (Optional) The name of the private DNS zone group. One will be generated if not set.
- `private_dns_zone_resource_ids` - (Optional) A set of resource IDs of private DNS zones to associate with the private endpoint. If not set, no zone groups will be created and the private endpoint will not be associated with any private DNS zones. DNS records must be managed external to this module.
- `application_security_group_resource_ids` - (Optional) A map of resource IDs of application security groups to associate with the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
- `private_service_connection_name` - (Optional) The name of the private service connection. One will be generated if not set.
- `network_interface_name` - (Optional) The name of the network interface. One will be generated if not set.
- `location` - (Optional) The Azure location where the resources will be deployed. Defaults to the location of the resource group.
- `resource_group_name` - (Optional) The resource group where the resources will be deployed. Defaults to the resource group of this resource.
- `ip_configurations` - (Optional) A map of IP configurations to create on the private endpoint. If not specified the platform will create one. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  - `name` - The name of the IP configuration.
  - `private_ip_address` - The private IP address of the IP configuration.

Type:

```hcl
map(object({
    name = optional(string, null)
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
    })), {})
    lock = optional(object({
      name = optional(string, null)
      kind = optional(string, "None")
    }), {})
    tags                                    = optional(map(any), null)
    subnet_resource_id                      = string
    private_dns_zone_group_name             = optional(string, "default")
    private_dns_zone_resource_ids           = optional(set(string), [])
    application_security_group_associations = optional(map(string), {})
    private_service_connection_name         = optional(string, null)
    network_interface_name                  = optional(string, null)
    location                                = optional(string, null)
    resource_group_name                     = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
  }))
```

Default: `{}`

### <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled)

Description: Whether public network access is enabled for the workspace. Defaults to true.

Type: `bool`

Default: `true`

### <a name="input_purview_id"></a> [purview\_id](#input\_purview\_id)

Description: The ID of the Purview account to link to the Synapse workspace. If not specified, no link will be created.

Type: `string`

Default: `null`

### <a name="input_role_assignments"></a> [role\_assignments](#input\_role\_assignments)

Description: A map of role assignments to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - The description of the role assignment.
- `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - The condition which will be used to scope the role assignment.
- `condition_version` - The version of the condition syntax. Valid values are '2.0'.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.

Type:

```hcl
map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_sql_administrator_login"></a> [sql\_administrator\_login](#input\_sql\_administrator\_login)

Description: Specifies The login name of the SQL administrator. Changing this forces a new resource to be created. If this is not provided customer\_managed\_key must be provided.

Type: `string`

Default: `"SQLAdmin"`

### <a name="input_sql_administrator_login_password"></a> [sql\_administrator\_login\_password](#input\_sql\_administrator\_login\_password)

Description: The Password associated with the sql\_administrator\_login for the SQL administrator. If this is not provided customer\_managed\_key must be provided.

Type: `string`

Default: `"null"`

### <a name="input_sql_identity_control_enabled"></a> [sql\_identity\_control\_enabled](#input\_sql\_identity\_control\_enabled)

Description: Are pipelines (running as workspace's system assigned identity) allowed to access SQL pools?

Type: `bool`

Default: `false`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: The map of tags to be applied to the resource

Type: `map(any)`

Default: `{}`

### <a name="input_use_access_policy"></a> [use\_access\_policy](#input\_use\_access\_policy)

Description: Use access policy instead of RBAC role

Type: `bool`

Default: `false`

## Outputs

The following outputs are exported:

### <a name="output_synapse_workspace"></a> [synapse\_workspace](#output\_synapse\_workspace)

Description: This is the full output for the resource.

### <a name="output_synapse_workspace_id"></a> [synapse\_workspace\_id](#output\_synapse\_workspace\_id)

Description: This is the full output for the resource.

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->