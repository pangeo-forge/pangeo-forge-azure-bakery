#!/bin/bash

ROOT=$1
echo "------------------------------------------"
echo "       Pangeo Forge - Azure bakery"
echo "       ----  LOKI INSTALLER ----"
echo "------------------------------------------"
echo $ROOT
echo "- Running kubernetes connector script"
$ROOT/scripts/k8s-connect.sh
if [ $? != 0 ]; then
  exit 1
fi


echo "- Adding helm repos"
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

echo "- Deploying the loki stack"
helm install loki-stack grafana/loki-stack \
                                --replace \
                                --create-namespace \
                                --namespace loki-stack \
                                --set promtail.enabled=true,loki.persistence.enabled=true,loki.persistence.size=100Gi,grafana.enabled=true
