## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.5.2"
}

data "azurerm_client_config" "current" {}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"

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

# Creating Key vault to store sql admin secrets

module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.0"

  location            = azurerm_resource_group.this.location
  name                = module.naming.key_vault.name_unique
  resource_group_name = azurerm_resource_group.this.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  enable_telemetry    = var.enable_telemetry
  keys = {
    synapse_cmk_key = {
      name     = "synapse-cmk-key"
      key_type = "RSA"
      key_size = 2048
      key_opts = ["unwrapKey", "wrapKey"]
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
  sku_name = "standard"
  wait_for_rbac_before_secret_operations = {
    create = "60s"
  }

  depends_on = [azurerm_resource_group.this]
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

resource "azurerm_storage_data_lake_gen2_filesystem" "adls_fs" {
  name               = "synapseadlsfs"
  storage_account_id = azurerm_storage_account.adls.id

  depends_on = [azurerm_role_assignment.adls_blob_contributor]
}

# This is the module call for Synapse Workspace
# This module creates a Synapse Workspace with the specified parameters.
# This module creates a Synapse Workspace with the specified parameters.
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.
module "synapse" {
  source = "../.."

  location = azurerm_resource_group.this.location
  # source             = "Azure/avm-res-synapse-workspace/azurerm"
  name                                 = "synapse-cmk-workspace-avm-01"
  resource_group_name                  = azurerm_resource_group.this.name
  sql_administrator_login_password     = null
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.adls_fs.id
  aad_admin_obj_id                     = data.azurerm_client_config.current.object_id # Object ID of the AAD admin
  azuread_authentication_only          = true
  cmk_enabled                          = var.cmk_enabled
  cmk_key_name                         = "synapse-cmk-key" # Name of the customer managed key
  cmk_key_versionless_id               = module.key_vault.keys.synapse_cmk_key.versionless_id
  enable_telemetry                     = var.enable_telemetry # see variables.tf
  identity_type                        = "SystemAssigned"
  key_vault_id                         = module.key_vault.resource_id
  sql_administrator_login              = var.sql_administrator_login
  tags                                 = var.tags
  use_access_policy                    = false

  depends_on = [
    module.key_vault,
    azurerm_storage_data_lake_gen2_filesystem.adls_fs
  ]
}
