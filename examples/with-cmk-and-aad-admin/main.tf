terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.28.0, < 5.0.0"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.5.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

data "azurerm_client_config" "current" {}

module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.5.2"
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"

  unique-length = 7
}

resource "azurerm_resource_group" "this" {
  location = module.regions.regions_by_display_name["East US 2"].name
  name     = module.naming.resource_group.name_unique
}

data "http" "ip" {
  url = "https://api.ipify.org/"
  retry {
    attempts     = 5
    max_delay_ms = 1000
    min_delay_ms = 500
  }
}


module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.0"

  location            = azurerm_resource_group.this.location
  name                = module.naming.key_vault.name_unique
  resource_group_name = azurerm_resource_group.this.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
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

module "synapse" {
  source = "../.."

  location                             = azurerm_resource_group.this.location
  name                                 = "synapse-cmk-workspace-avm-01"
  resource_group_name                  = azurerm_resource_group.this.name
  sql_administrator_login_password     = null
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.adls_fs.id
  customer_managed_key = {
    key_versionless_id     = module.key_vault.keys["synapse-cmk-key"].versionless_id
    key_name               = module.key_vault.keys["synapse-cmk-key"].name
    user_assigned_identity = null
  }
  customer_managed_key_enabled         = true
  entra_id_admin_object_id             = data.azurerm_client_config.current.object_id
  entra_id_authentication_only_enabled = true
  managed_identities = {
    system_assigned = true
  }
  sql_administrator_login = var.sql_administrator_login
  tags                    = var.tags

  depends_on = [
    module.key_vault,
    azurerm_storage_data_lake_gen2_filesystem.adls_fs
  ]
}
