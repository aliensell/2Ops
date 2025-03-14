provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "terraform_backend_rg" {
  name     = "terraform-backend-rg"
  location = "West Europe"
}

resource "azurerm_storage_account" "terraform_backend_sa" {
  name                     = "tfbackendstorage"
  resource_group_name      = azurerm_resource_group.terraform_backend_rg.name
  location                 = "West Europe"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "backend_container" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.terraform_backend_sa.name
  container_access_type = "private"
}

resource "azurerm_storage_account_management_policy" "terraform_policy" {
  storage_account_id = azurerm_storage_account.terraform_backend_sa.id
  name               = "terraform-backend-policy"
}
