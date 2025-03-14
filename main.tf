provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "terraform_backend_rg" {
  name     = "terraform-backend-rg"
  location = "West Europe"
}

module "backend" {
  source              = "./modules/backend"
  resource_group_name = azurerm_resource_group.terraform_backend_rg.name
}

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
      version = "=4.1.0"
    }
  }
}

variable "environment" {
  description = "The environment to deploy (DEV/QA)"
  type        = string
}

resource "azurerm_resource_group" "dev_rg" {
  count    = var.environment == "DEV" ? 1 : 0
  name     = "example-dev-rg"
  location = "West Europe"
}

resource "azurerm_resource_group" "qa_rg" {
  count    = var.environment == "QA" ? 1 : 0
  name     = "example-qa-rg"
  location = "West Europe"
}

resource "azurerm_virtual_network" "dev_vnet" {
  count               = var.environment == "DEV" ? 1 : 0
  name                = "vnet-${var.environment}"
  resource_group_name = azurerm_resource_group.dev_rg[0].name
  location            = "West Europe"
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  count                = var.environment == "DEV" ? 1 : 0
  name                 = "subnet-${var.environment}"
  resource_group_name  = azurerm_resource_group.dev_rg[0].name
  virtual_network_name = azurerm_virtual_network.dev_vnet[0].name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_storage_account" "dev_storage" {
  count                    = var.environment == "DEV" ? 1 : 0
  name                     = "mystorage-${var.environment}"
  resource_group_name      = azurerm_resource_group.dev_rg[0].name
  location                 = "West Europe"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [azurerm_subnet.subnet[0].id]
  }
}

resource "azurerm_key_vault" "qa_keyvault" {
  count              = var.environment == "QA" ? 1 : 0
  name               = "mykeyvault-${var.environment}"
  resource_group_name = azurerm_resource_group.qa_rg[0].name
  location            = "West Europe"
  sku_name            = "standard"
}
