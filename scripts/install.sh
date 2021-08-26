#!/bin/bash
poetry install
poetry run dotenv run terraform -chdir="terraform/" plan
poetry run dotenv run terraform -chdir="terraform/" apply -auto-approve
./scripts/k8s-connect.sh
poetry run dotenv run sh -c 'kubectl create namespace $BAKERY_NAMESPACE --dry-run=client -o yaml | kubectl apply -f - && cat kubernetes/prefect_agent_conf.yaml | envsubst | kubectl apply -f -'
poetry run dotenv run bash ./scripts/retrieve_flow_storage_values.sh
