terraform {
  required_version = ">= 1.5.0"


  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.28.0, < 5.0.0" # Latest version published a day ago [1](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0, < 4.0" # Latest stable version
    }
  }
}

provider "azurerm" {
  features {}
}