#!/bin/bash
az account show
RESULT_LOGIN=$?
if [ "$RESULT_LOGIN" != 0 ]; then
  az login
fi
ACCOUNT_DETAILS=$(az account show)
TENANT_ID=$(echo "$ACCOUNT_DETAILS" | grep "tenantId" | sed -rn "s/\"tenantId\": \"(.*)\",/\1/p" | xargs)
SUBSCRIPTION_ID=$(echo "$ACCOUNT_DETAILS" | grep "id" | sed -rn "s/\"id\": \"(.*)\",/\1/p" | xargs)
echo "Tenant is:$TENANT_ID"
echo "Subscription is:$SUBSCRIPTION_ID"

RESULT_SP_CREATE=$(az ad sp create-for-rbac --name "$SERVICE_PRINCIPAL_NAME")
# shellcheck disable=SC2181
if [ $? != 0 ]; then
  echo "SP Creation failed"
  exit 1
fi

APP_ID=$(echo "$RESULT_SP_CREATE" | grep "appId" | sed -rn "s/\"appId\": \"(.*)\",/\1/p" | xargs)
APP_PASSWORD=$(echo "$RESULT_SP_CREATE" | grep "password" | sed -rn "s/\"password\": \"(.*)\",/\1/p" | xargs)
echo "App ID is $APP_ID"
APP_OBJECT_ID=$(az ad sp list --filter "appId eq '$APP_ID'" --query="[].objectId" -o tsv)
echo App Object ID:$APP_OBJECT_ID

az role assignment create --assignee "$APP_OBJECT_ID" --role "Storage Blob Data Contributor"
az role assignment create --assignee "$APP_OBJECT_ID" --role "User Access Administrator"
az role assignment create --assignee "$APP_OBJECT_ID" --role "Azure Kubernetes Service Cluster User Role"

python3 ./scripts/replace_or_insert_value.py "$SUBSCRIPTION_ID" ARM_SUBSCRIPTION_ID
python3 ./scripts/replace_or_insert_value.py "$TENANT_ID" ARM_TENANT_ID
python3 ./scripts/replace_or_insert_value.py "$APP_ID" ARM_CLIENT_ID
python3 ./scripts/replace_or_insert_value.py "$APP_PASSWORD" ARM_CLIENT_SECRET