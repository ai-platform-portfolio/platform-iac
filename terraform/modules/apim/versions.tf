terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.81, < 5.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.13, < 3.0"
    }
  }
}
