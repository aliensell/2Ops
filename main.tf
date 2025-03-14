terraform {
  required_version = ">= 1.5.0"
  
  # Backend configuration (use the storage account and resource group created by Terraform)
  backend "azurerm" {
    resource_group_name  = azurerm_resource_group.backend.name
    storage_account_name = azurerm_storage_account.backend.name
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.1.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Create the Resource Group
resource "azurerm_resource_group" "backend" {
  name     = "terraform-backend-rg"
  location = "East US"  # Set your desired Azure region
}

# Create the Storage Account for Backend
resource "azurerm_storage_account" "backend" {
  name                     = "tfbackendstorage"
  resource_group_name       = azurerm_resource_group.backend.name
  location                 = azurerm_resource_group.backend.location
  account_tier               = "Standard"
  account_replication_type = "LRS"
}

# Create the Blob Container for storing Terraform state
resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.backend.name
  container_access_type = "private"
}
