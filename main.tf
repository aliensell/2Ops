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

# This null_resource triggers the backend initialization after the resources are created
resource "null_resource" "init_backend" {
  depends_on = [
    azurerm_storage_container.tfstate
  ]

  provisioner "local-exec" {
    command = "terraform init -backend-config='resource_group_name=${azurerm_resource_group.backend.name}' -backend-config='storage_account_name=${azurerm_storage_account.backend.name}' -backend-config='container_name=tfstate' -backend-config='key=terraform.tfstate'"
  }
}
