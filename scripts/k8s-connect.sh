#!/bin/bash
ROOT=$(pwd)
echo "------------------------------------------"
echo "       Pangeo Forge - Azure bakery"
echo "   ----  KUBERNETES CONNECTOR ----"
echo "------------------------------------------"
#echo "- Running prepare script"
#source "$ROOT/scripts/prepare.sh" "$ROOT"
echo "- Checking prerequisites..."
OK=1
if [ -z "${TF_VAR_identifier}" ]; then
  echo "[X] - TF_VAR_identifier is not set"
  OK=0
else
  echo "TF_VAR_identifier is set to ${TF_VAR_identifier}"
fi

if [ $OK == 0 ]; then
  exit 1
fi
echo "- Beginning Azure kubernetes init"
az aks get-credentials --overwrite-existing --resource-group "${TF_VAR_identifier}-bakery-resource-group" --name "${TF_VAR_identifier}-bakery-cluster"
CONTEXT_NAME="${TF_VAR_identifier}-bakery-cluster"
set -e
kubectl config use-context "$CONTEXT_NAME"