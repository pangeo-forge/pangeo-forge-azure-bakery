.PHONEY: install setup-remote-state destroy-remote-state init lint format plan apply destroy configure-kubectl setup-agent retrieve-flow-storage-container retrieve-storage-connection-string

install:
	poetry install

setup-remote-state:
	poetry run dotenv run bash setup_remote_state.sh

destroy-remote-state:
	poetry run dotenv run sh -c "az group delete --name $$TF_VAR_identifier-bakery-remote-state-resource-group --yes"

init:
	poetry run dotenv run terraform -chdir="terraform/" init

lint: init
	terraform -chdir="terraform/" validate

format:
	terraform -chdir="terraform/" fmt

plan: init
	poetry run dotenv run terraform -chdir="terraform/" plan

apply: init
	poetry run dotenv run terraform -chdir="terraform/" apply -auto-approve

destroy: init
	poetry run dotenv run terraform -chdir="terraform/" destroy -auto-approve

configure-kubectl:
	az aks get-credentials --overwrite-existing --resource-group $$(terraform -chdir="terraform" output -raw bakery_resource_group_name) --name $$(terraform -chdir="terraform" output -raw bakery_cluster_name)

setup-agent:
	poetry run dotenv run sh -c 'kubectl create namespace $$BAKERY_NAMESPACE --dry-run=client -o yaml | kubectl apply -f - && cat prefect_agent_conf.yaml | envsubst | kubectl apply -f -'

retrieve-flow-storage-container:
	echo $$(terraform -chdir="terraform" output -raw bakery_flow_storage_container_name)

retrieve-storage-connection-string:
	poetry run dotenv run sh -c 'az storage account show-connection-string -g $$(terraform -chdir="terraform" output -raw bakery_resource_group_name) -n $$(terraform -chdir="terraform" output -raw bakery_flow_storage_account_name)' | jq '.connectionString'
