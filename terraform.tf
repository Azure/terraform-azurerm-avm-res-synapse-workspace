terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.4"
    }
    # azapi = {
    #   source  = "azure/azapi"
    #   version = ">= 1.12.0"
    # }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.28.0, < 5.0.0"
    }
    # http = {
    #   source  = "hashicorp/http"
    #   version = ">= 3.5.0"
    # }
    # local = {
    #   source  = "hashicorp/local"
    #   version = ">= 2.4.0"
    # }
    modtm = {
      source  = "azure/modtm"
      version = ">= 0.1.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.7.0"
    }
  }
}
