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
    random = {
      source  = "hashicorp/random"
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
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.9.0" # use the latest published version
}

resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"

  unique-length = 7
}

resource "azurerm_resource_group" "this" {
  location = "East US 2"
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

resource "random_password" "synapse_sql_admin_password" {
  length  = 16
  special = true
}

data "azurerm_client_config" "current" {}


module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.0"

  location            = azurerm_resource_group.this.location
  name                = module.naming.key_vault.name_unique
  resource_group_name = azurerm_resource_group.this.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
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
    test_secret = coalesce(var.synapse_sql_admin_password, random_password.synapse_sql_admin_password.result)
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

module "synapse" {
  source = "../.."

  location                             = azurerm_resource_group.this.location
  name                                 = "synapse-test-workspace-avm-01"
  resource_group_name                  = azurerm_resource_group.this.name
  sql_administrator_login_password     = data.azurerm_key_vault_secret.sql_admin.value
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.adls_fs.id
  customer_managed_key                 = null
  customer_managed_key_enabled         = false
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
