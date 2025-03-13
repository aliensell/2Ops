# Terraform Configuration for Azure Deployment

terraform {
  required_version = ">= 1.5.0"
  backend "azurerm" {
    resource_group_name  = "terraform-backend-rg"
    storage_account_name = "tfbackendstorage"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.74"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "environment" {
  description = "The environment to deploy (DEV/QA)"
  type        = string
}

resource "azurerm_resource_group" "dev_rg" {
  count    = var.environment == "DEV" ? 1 : 0
  name     = "example-dev-rg"
  location = "East US"
}

resource "azurerm_resource_group" "qa_rg" {
  count    = var.environment == "QA" ? 1 : 0
  name     = "example-qa-rg"
  location = "East US"
}

resource "azurerm_virtual_network" "vnet" {
  count               = var.environment == "DEV" ? 1 : 0
  name                = "example-vnet-${var.environment}"
  resource_group_name = azurerm_resource_group.dev_rg[0].name
  location            = "East US"
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  count                = var.environment == "DEV" ? 1 : 0
  name                 = "example-subnet"
  resource_group_name  = azurerm_resource_group.dev_rg[0].name
  virtual_network_name = azurerm_virtual_network.vnet[0].name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_storage_account" "dev_storage" {
  count                    = var.environment == "DEV" ? 1 : 0
  name                     = "examplestorage${var.environment}"
  resource_group_name      = azurerm_resource_group.dev_rg[0].name
  location                 = "East US"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [azurerm_subnet.subnet[0].id]
  }
}

resource "azurerm_key_vault" "qa_keyvault" {
  count              = var.environment == "QA" ? 1 : 0
  name               = "examplekeyvault${var.environment}"
  resource_group_name = azurerm_resource_group.qa_rg[0].name
  location            = "East US"
  sku_name            = "standard"
}
