<!-- BEGIN_TF_DOCS -->
# Default example

This deploys the module in its simplest form.

```hcl
## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.5.2"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = ">= 0.3.0"

  unique-length = 7
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = "East US 2"
  name     = module.naming.resource_group.name_unique
}

# Get current IP address for use in KV firewall rules
data "http" "ip" {
  url = "https://api.ipify.org/"
  retry {
    attempts     = 5
    max_delay_ms = 1000
    min_delay_ms = 500
  }
}

resource "random_password" "synapse_sql_admin_password" {
  length  = 16
  special = true
}

data "azurerm_client_config" "current" {}

# Creating Key vault to store sql admin secrets

module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.0"

  location            = azurerm_resource_group.this.location
  name                = module.naming.key_vault.name_unique
  resource_group_name = azurerm_resource_group.this.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  enable_telemetry    = var.enable_telemetry
  network_acls = {
    bypass   = "AzureServices"
    ip_rules = ["${data.http.ip.response_body}/32"]
  }
  public_network_access_enabled = true
  role_assignments = {
    deployment_user_kv_admin = {
      role_definition_id_or_name = "Key Vault Administrator"
      principal_id               = data.azurerm_client_config.current.object_id
    }
  }
  secrets = {
    test_secret = {
      name = var.sql_administrator_login
    }
  }
  secrets_value = {
    test_secret = random_password.synapse_sql_admin_password.result
  }
  sku_name = "standard"
  wait_for_rbac_before_secret_operations = {
    create = "60s"
  }

  depends_on = [azurerm_resource_group.this]
}

data "azurerm_key_vault_secret" "sql_admin" {
  key_vault_id = module.key_vault.resource_id
  name         = var.sql_administrator_login

  depends_on = [module.key_vault]
}

resource "azurerm_storage_account" "adls" {
  account_replication_type      = "GRS"
  account_tier                  = "Standard"
  location                      = azurerm_resource_group.this.location
  name                          = module.naming.storage_account.name_unique
  resource_group_name           = azurerm_resource_group.this.name
  account_kind                  = "StorageV2"
  https_traffic_only_enabled    = true
  is_hns_enabled                = true
  min_tls_version               = "TLS1_2"
  public_network_access_enabled = true
  shared_access_key_enabled     = true
  tags                          = var.tags

  depends_on = [azurerm_resource_group.this]
}

resource "azurerm_role_assignment" "adls_blob_contributor" {
  principal_id         = data.azurerm_client_config.current.object_id
  scope                = azurerm_storage_account.adls.id
  role_definition_name = "Storage Blob Data Contributor"

  depends_on = [azurerm_storage_account.adls]
}

resource "azurerm_storage_data_lake_gen2_filesystem" "synapseadls_fs" {
  name               = "synapseadlsfs"
  storage_account_id = azurerm_storage_account.adls.id

  depends_on = [azurerm_role_assignment.adls_blob_contributor]
}

# This is the module call for Synapse Workspace
# This module creates a Synapse Workspace with the specified parameters.
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.
module "synapse" {
  source = "../.."

  location = azurerm_resource_group.this.location
  # source             = "Azure/avm-res-synapse-workspace/azurerm"
  name                                 = "synapse-testado-workspace-avm-01"
  resource_group_name                  = azurerm_resource_group.this.name
  sql_administrator_login_password     = data.azurerm_key_vault_secret.sql_admin.value
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.synapseadls_fs.id
  azure_devops_repo = {
    account_name    = "devops-account"
    branch_name     = "main"
    project_name    = "synapse-project"
    repository_name = "synapse-repo"
    root_folder     = "/AzureSynapse"
    last_commit_id  = "abc123def456"
    tenant_id       = "00000000-0000-0000-0000-000000000000"
  }
  cmk_enabled             = var.cmk_enabled
  enable_telemetry        = var.enable_telemetry # see variables.tf
  identity_type           = "SystemAssigned"
  sql_administrator_login = var.sql_administrator_login
  tags                    = var.tags

  depends_on = [
    module.key_vault,
    azurerm_storage_data_lake_gen2_filesystem.synapseadls_fs
  ]
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.5.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 4.28.0, < 5.0.0)

- <a name="requirement_http"></a> [http](#requirement\_http) (>= 3.5.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (>= 3.5.0)

## Resources

The following resources are used by this module:

- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_role_assignment.adls_blob_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_storage_account.adls](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) (resource)
- [azurerm_storage_data_lake_gen2_filesystem.synapseadls_fs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_data_lake_gen2_filesystem) (resource)
- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)
- [random_password.synapse_sql_admin_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) (resource)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [azurerm_key_vault_secret.sql_admin](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_secret) (data source)
- [http_http.ip](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_cmk_enabled"></a> [cmk\_enabled](#input\_cmk\_enabled)

Description: Flag to enable the customer\_managed\_key block.

Type: `bool`

Default: `false`

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_sql_administrator_login"></a> [sql\_administrator\_login](#input\_sql\_administrator\_login)

Description: Specifies The login name of the SQL administrator. Changing this forces a new resource to be created. If this is not provided customer\_managed\_key must be provided.

Type: `string`

Default: `"SQLAdmin"`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: The map of tags to be applied to the resource

Type: `map(any)`

Default: `{}`

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_key_vault"></a> [key\_vault](#module\_key\_vault)

Source: Azure/avm-res-keyvault-vault/azurerm

Version: 0.10.0

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: >= 0.3.0

### <a name="module_regions"></a> [regions](#module\_regions)

Source: Azure/avm-utl-regions/azurerm

Version: 0.5.2

### <a name="module_synapse"></a> [synapse](#module\_synapse)

Source: ../..

Version:

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->