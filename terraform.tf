terraform {
  required_version = ">= 1.5.0"


  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = ">= 1.12.0, < 2.0" # Latest stable as of May 2024
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.28.0, < 5.0" # Latest version published a day ago [1](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0, < 4.0" # Latest stable version
    }
  }
}
