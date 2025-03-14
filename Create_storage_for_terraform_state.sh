#!/bin/bash

RESOURCE_GROUP_NAME=terraform-backend-rg
STORAGE_ACCOUNT_NAME=backendstorageterraform
CONTAINER_NAME=tfstate

# Check if resource group exists (if yes skip, if no create)
az group show --name $RESOURCE_GROUP_NAME &> /dev/null
if [ $? -ne 0 ]; then
    echo "Resource group does not exist. Creating resource group..."
    az group create --name $RESOURCE_GROUP_NAME --location westeurope
else
    echo "Resource group $RESOURCE_GROUP_NAME already exists."
fi

# Check if storage account already exists (if yes skip, if no create)
STORAGE_ACCOUNT_EXIST=$(az storage account check-name --name $STORAGE_ACCOUNT_NAME --query 'nameAvailable' -o tsv)

if [ "$STORAGE_ACCOUNT_EXIST" == "true" ]; then
    echo "Storage account name $STORAGE_ACCOUNT_NAME is available. Creating storage account..."
    az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --location westeurope --sku Standard_LRS --encryption-services blob
else
    echo "Storage account $STORAGE_ACCOUNT_NAME already exists. Skipping creation."
fi

# Check if container exists (if yes skip, if no create)
CONTAINER_EXIST=$(az storage container list --account-name $STORAGE_ACCOUNT_NAME --query "[?name=='$CONTAINER_NAME'].name" -o tsv)

if [ -z "$CONTAINER_EXIST" ]; then
    echo "Container $CONTAINER_NAME does not exist. Creating container..."
    az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME
else
    echo "Container $CONTAINER_NAME already exists. Skipping creation."
fi
