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

# Creating Key vault to store Customer-managed Key (CMK)

module "key_vault" {
  source = "Azure/avm-res-keyvault-vault/azurerm"

  location            = azurerm_resource_group.this.location
  name                = module.naming.key_vault.name_unique
  resource_group_name = azurerm_resource_group.this.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  enable_telemetry    = var.enable_telemetry
  # legacy_access_policies_enabled = true
  # legacy_access_policies = {
  #   test = {
  #     object_id               = data.azurerm_client_config.this.object_id
  #     key_permissions = ["Create", "Get", "Delete", "Purge", "GetRotationPolicy"]
  #   }
  # }
  keys = {
    cmk_for_storage_account = {
      key_opts = [
        "unwrapKey",
        "wrapKey"
      ]
      key_type = "RSA"
      name     = "workspaceencryptionkey"
      key_size = 2048
    }
  }
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
  aad_admin_obj_id                     = ""
  cmk_enabled                          = true
  key_vault_id                         = module.key_vault.resource_id
  key_versionless_id                   = module.key_vault.keys_resource_ids["workspaceencryptionkey"].versionless_id
  location                             = azurerm_resource_group.this.location
  managed_identities = {
    system_assigned = true
  }
  synapse_key_name = var.synapse_key_name

  depends_on = [
    module.key_vault,
    moduule.azure_data_lake_storage
  ]
}
