#!/bin/bash

REGISTRY_NAME=$(terraform -chdir="terraform" output -raw bakery_image_registry_name)
LOCAL_TAG=pangeo-forge-azure-bakery-image
REMOTE_TAG=$REGISTRY_NAME.azurecr.io/$LOCAL_TAG

az acr login --name $REGISTRY_NAME

docker build -t $LOCAL_TAG -f ./images/Dockerfile ./images/

docker tag $LOCAL_TAG $REMOTE_TAG

docker push $REMOTE_TAG

printf "\r\nCopy the following line into your .env file:\r\n\r\n"

echo "AZURE_BAKERY_IMAGE=\"$REMOTE_TAG\""
