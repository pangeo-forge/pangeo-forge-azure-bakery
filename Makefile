.PHONEY: install setup-remote-state destroy-remote-state init lint format plan apply destroy configure-kubectl setup-agent build-and-push-image retrieve-flow-storage-values deploy-bakery

install:
	poetry install

setup-remote-state:
	poetry run dotenv run bash ./scripts/setup_remote_state.sh

destroy-remote-state:
	poetry run dotenv run sh -c 'az group delete --resource-group $$TF_VAR_identifier-bakery-remote-state-resource-group --yes'

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

retrieve-flow-storage-values:
	poetry run dotenv run bash ./scripts/retrieve_flow_storage_values.sh

build-and-push-image:
	poetry run dotenv run bash ./scripts/build_and_push_image.sh

deploy-bakery: setup-remote-state apply build-and-push-image configure-kubectl setup-agent retrieve-flow-storage-values
