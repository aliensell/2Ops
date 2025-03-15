terraform {
  required_version = ">= 1.5.0"
  backend "azurerm" {
    resource_group_name  = "terraform-backend-rg"
    storage_account_name = "backendstorageterraform"
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

data "azurerm_client_config" "current" {}

variable "environment" {
  description = "The environment to deploy (DEV/QA)"
  type        = string
}

variable "mytenantid" {
  description = "tenant_id which taken from GitHub secrets"
  type        = string
}

variable "mysubscriptionid" {
  description = "subscription_id which taken from GitHub secrets"
  type        = string
}

provider "azurerm" {
  #subscription_id = data.azurerm_client_config.current.subscription_id
  subscription_id = "${var.mysubscriptionid}"
  features {}
}

resource "azurerm_resource_group" "dev_rg" {
  count    = var.environment == "DEV" ? 1 : 0
  name     = "dev-rg"
  location = "West Europe"
}

resource "azurerm_resource_group" "qa_rg" {
  count    = var.environment == "QA" ? 1 : 0
  name     = "qa-rg"
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
  service_endpoints    = ["Microsoft.Storage"]
}

resource "azurerm_subnet" "subnet_aks" {
  count                = var.environment == "DEV" ? 1 : 0
  name                 = "subnet-aks-${var.environment}"
  resource_group_name  = azurerm_resource_group.dev_rg[0].name
  virtual_network_name = azurerm_virtual_network.dev_vnet[0].name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_kubernetes_cluster" "aks" {
  count                    = var.environment == "DEV" ? 1 : 0
  name                     = "aks-cluster-dev"
  resource_group_name      = azurerm_resource_group.dev_rg[0].name
  location                 = azurerm_resource_group.dev_rg[0].location
  dns_prefix               = "aksdev"

  default_node_pool {
    name               = "default"
    node_count         = 2
    vm_size            = "Standard_DS2_v2"
    vnet_subnet_id     = azurerm_subnet.subnet_aks[0].id
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
    service_cidr = "10.0.4.0/24"
  }
  
  private_cluster_enabled = true
  
  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "dev"
  }
}

resource "azurerm_storage_account" "dev_storage" {
  count                    = var.environment == "DEV" ? 1 : 0
  name                     = "mystoragedev"
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
  #tenant_id          = "bbaf146a-d527-4a60-931a-85358eb8160d"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    key_permissions     = [ "Get", "List", "Create", "Delete" ]
    secret_permissions  = [ "Get", "List" ]
    storage_permissions = [ "Get", "List" ]
  }
}
