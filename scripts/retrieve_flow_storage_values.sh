#!/bin/bash

CONTAINER_NAME=$(terraform -chdir="terraform" output -raw bakery_flow_storage_container_name)
CONNECTION_STRING=$(az storage account show-connection-string -g $(terraform -chdir="terraform" output -raw bakery_resource_group_name) -n $(terraform -chdir="terraform" output -raw bakery_flow_storage_account_name) | jq -r '.connectionString')

python3 ./scripts/replace_or_insert_value.py $CONTAINER_NAME FLOW_STORAGE_CONTAINER
python3 ./scripts/replace_or_insert_value.py $CONNECTION_STRING FLOW_STORAGE_CONNECTION_STRING
