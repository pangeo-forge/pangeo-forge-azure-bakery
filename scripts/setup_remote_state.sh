#!/bin/bash

TAGS="Project=pangeo-forge-azure-bakery Client=Planetary-Computer Owner=$TF_VAR_owner Stack=$TF_VAR_identifier"
RESOURCE_GROUP_NAME="$TF_VAR_identifier-bakery-remote-state-resource-group"
STORAGE_ACCOUNT_NAME="remotestatestoreacc"
CONTAINER_NAME="$TF_VAR_identifier-bakery-remote-state-storage-container"

# Remove terraform/.terraform if found: If not removed, terraform init will fail if you have made a new Remote State, so we'll clean it up beforehand just to make sure
if [ -d "./terraform/.terraform" ]
then
    rm -rf "./terraform/.terraform"
fi

# Login
az login --service-principal --username $ARM_CLIENT_ID --password $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID

# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location "$TF_VAR_region" --tags $TAGS

# Create storage account
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob --tags $TAGS

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query '[0].value' -o tsv)

# Create blob container
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --account-key $ACCOUNT_KEY

INIT_ARGS="-backend-config='resource_group_name=$RESOURCE_GROUP_NAME' -backend-config='storage_account_name=$STORAGE_ACCOUNT_NAME' -backend-config='container_name=$CONTAINER_NAME' -backend-config='access_key=$ACCOUNT_KEY' -backend-config='key=$TF_VAR_identifier-bakery.state'"

python3 ./scripts/replace_or_insert_value.py "$INIT_ARGS" TF_CLI_ARGS_init
