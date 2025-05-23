<!-- BEGIN_TF_DOCS -->
# Default example

This deploys the module in its simplest form.

```hcl
## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/regions/azurerm"
  version = ">= 0.8.0"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

# This allow use to randomize the name of resources
resource "random_string" "this" {
  length  = 6
  special = false
  upper   = false
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = ">= 0.4.1"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = module.regions.regions[random_integer.region_index.result].name
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
  source = "Azure/avm-res-keyvault-vault/azurerm"

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
    test_secret = coalesce(var.sql_administrator_login_password, random_password.synapse_sql_admin_password)
  }
  wait_for_rbac_before_secret_operations = {
    create = "60s"
  }

  depends_on = [azurerm_resource_group.this]
}

# Creating ADLS and file system for Synapse 

module "azure_data_lake_storage" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.2.7"

  location                      = azurerm_resource_group.this.location
  name                          = module.naming.storage_account.name_unique
  resource_group_name           = azurerm_resource_group.this.name
  account_kind                  = "StorageV2"
  account_replication_type      = "LRS"
  account_tier                  = "Standard"
  https_traffic_only_enabled    = true
  is_hns_enabled                = true
  min_tls_version               = "TLS1_2"
  public_network_access_enabled = true
  role_assignments = {
    role_assignment_1 = {
      role_definition_id_or_name       = "Owner"
      principal_id                     = data.azurerm_client_config.current.object_id
      skip_service_principal_aad_check = false
    },
  }
  shared_access_key_enabled = true
  storage_data_lake_gen2_filesystem = {
    name = var.storage_data_lake_gen2_filesystem_name
  }
  tags = var.tags

  depends_on = [azurerm_resource_group.this]
}

data "azurerm_storage_data_lake_gen2_filesystem" "storage_data_lake_gen2_filesystem_id" {
  name               = var.storage_data_lake_gen2_filesystem_name
  storage_account_id = module.azure_data_lake_storage.id
}

# This is the module call for Synapse Workspace

module "azurerm_synapse_workspace" {
  source = "../.."

  name = "synapse-workspace"
  # source             = "Azure/avm-res-synapse-workspace"
  resource_group_name                  = azurerm_resource_group.this.name
  storage_data_lake_gen2_filesystem_id = data.azurerm_storage_data_lake_gen2_filesystem.storage_data_lake_gen2_filesystem_id
  location                             = azurerm_resource_group.this.location

  depends_on = [
    module.key_vault,
    moduule.azure_data_lake_storage
  ]
}
```

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

- <a name="provider_http"></a> [http](#provider\_http)

- <a name="provider_random"></a> [random](#provider\_random) (>= 3.6.0, < 4.0)

## Resources

The following resources are used by this module:

- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)
- [random_password.synapse_sql_admin_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) (resource)
- [random_string.this](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) (resource)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [azurerm_storage_data_lake_gen2_filesystem.storage_data_lake_gen2_filesystem_id](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/storage_data_lake_gen2_filesystem) (data source)
- [http_http.ip](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_storage_data_lake_gen2_filesystem_name"></a> [storage\_data\_lake\_gen2\_filesystem\_name](#input\_storage\_data\_lake\_gen2\_filesystem\_name)

Description: Specifies the name of storage data lake gen2 filesystem resource.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

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

### <a name="input_sql_administrator_login_password"></a> [sql\_administrator\_login\_password](#input\_sql\_administrator\_login\_password)

Description: The Password associated with the sql\_administrator\_login for the SQL administrator. If this is not provided customer\_managed\_key must be provided.

Type: `string`

Default: `"null"`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: The map of tags to be applied to the resource

Type: `map(any)`

Default: `{}`

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_azure_data_lake_storage"></a> [azure\_data\_lake\_storage](#module\_azure\_data\_lake\_storage)

Source: Azure/avm-res-storage-storageaccount/azurerm

Version: 0.2.7

### <a name="module_azurerm_synapse_workspace"></a> [azurerm\_synapse\_workspace](#module\_azurerm\_synapse\_workspace)

Source: ../..

Version:

### <a name="module_key_vault"></a> [key\_vault](#module\_key\_vault)

Source: Azure/avm-res-keyvault-vault/azurerm

Version:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: >= 0.4.1

### <a name="module_regions"></a> [regions](#module\_regions)

Source: Azure/regions/azurerm

Version: >= 0.8.0

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->