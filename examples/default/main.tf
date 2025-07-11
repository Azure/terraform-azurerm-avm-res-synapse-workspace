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

// NOTE: For automated testing purposes only, this example includes a generated random password.
// In real usage, do NOT rely on the example generated password as it will end up in terraform state.
// Module consumers should provide the password securely via variables, secret managers, or CI secrets.
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
    test_secret = var.synapse_sql_admin_password
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

# Creating ADLS and file system for Synapse

# module "azure_data_lake_storage" {
#   source                        = "Azure/avm-res-storage-storageaccount/azurerm"
#   version                       = "0.6.2"
#   location                      = azurerm_resource_group.this.location
#   name                          = module.naming.storage_account.name_unique
#   resource_group_name           = azurerm_resource_group.this.name
#   account_kind                  = "StorageV2"
#   account_replication_type      = "GRS"
#   account_tier                  = "Standard"
#   https_traffic_only_enabled    = true
#   is_hns_enabled                = true
#   min_tls_version               = "TLS1_2"
#   public_network_access_enabled = true
#   shared_access_key_enabled     = true
#   tags                          = var.tags

#   storage_data_lake_gen2_filesystem = {
#     synapseadlsfs = {
#       filesystem = {
#         name = "synapseadlsfs"
#       }
#     }
#   }

#   role_assignments = {
#     role_assignment_1 = {
#       role_definition_id_or_name       = "Storage Blob Data Contributor"
#       principal_id                     = data.azurerm_client_config.current.object_id
#       skip_service_principal_aad_check = false
#     }
#   }

#   depends_on = [azurerm_resource_group.this]
# }

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

resource "azurerm_storage_data_lake_gen2_filesystem" "adls_fs" {
  name               = "synapseadlsfs"
  storage_account_id = azurerm_storage_account.adls.id

  depends_on = [azurerm_role_assignment.adls_blob_contributor]
}

resource "azurerm_role_assignment" "adls_blob_contributor" {
  principal_id         = data.azurerm_client_config.current.object_id
  scope                = azurerm_storage_account.adls.id
  role_definition_name = "Storage Blob Data Contributor"

  depends_on = [azurerm_storage_account.adls]
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
  name                                 = "synapse-test-workspace-avm-01"
  resource_group_name                  = azurerm_resource_group.this.name
  sql_administrator_login_password     = data.azurerm_key_vault_secret.sql_admin.value
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.adls_fs.id
  cmk_enabled                          = var.cmk_enabled
  enable_telemetry                     = var.enable_telemetry # see variables.tf
  identity_type                        = "SystemAssigned"
  sql_administrator_login              = var.sql_administrator_login
  tags                                 = var.tags

  depends_on = [
    module.key_vault,
    azurerm_storage_data_lake_gen2_filesystem.adls_fs
  ]
}
