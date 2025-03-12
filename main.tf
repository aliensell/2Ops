terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.72.0"
    }
  }

  required_version = ">= 1.5.0"
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region to deploy the resources"
  type        = string
}
