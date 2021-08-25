.PHONY: install
install:
	poetry install

.PHONY: setup-remote-state
setup-remote-state:
	poetry run dotenv run bash ./scripts/setup_remote_state.sh

.PHONY: destroy-remote-state
destroy-remote-state:
	poetry run dotenv run sh -c 'az group delete --resource-group $$TF_VAR_identifier-bakery-remote-state-resource-group --yes'

.PHONY: init
init:
	poetry run dotenv run terraform -chdir="terraform/" init

.PHONY: lint-init
lint-init:
	terraform -chdir="terraform/" init -backend=false

.PHONY: lint
lint: lint-init
	terraform -chdir="terraform/" validate
	poetry run flake8 test/recipes/ scripts/
	poetry run isort --check-only --profile black test/recipes/ scripts/
	poetry run black --check --diff test/recipes/ scripts/

.PHONY: format
format:
	terraform -chdir="terraform/" fmt
	poetry run isort --profile black test/recipes/ scripts/
	poetry run black test/recipes/ scripts/

.PHONY: plan
plan: init
	poetry run dotenv run terraform -chdir="terraform/" plan

.PHONY: apply
apply: init
	poetry run dotenv run terraform -chdir="terraform/" apply -auto-approve

.PHONY: destroy
destroy: init
	poetry run dotenv run terraform -chdir="terraform/" destroy -auto-approve

.PHONY: configure-kubectl
configure-kubectl:
	az aks get-credentials --overwrite-existing --resource-group $$(terraform -chdir="terraform" output -raw bakery_resource_group_name) --name $$(terraform -chdir="terraform" output -raw bakery_cluster_name)

.PHONY: setup-agent
setup-agent:
	poetry run dotenv run sh -c 'kubectl create namespace $$BAKERY_NAMESPACE --dry-run=client -o yaml | kubectl apply -f - && cat kubernetes/prefect_agent_conf.yaml | envsubst | kubectl apply -f -'

.PHONY: retrieve-flow-storage-values
retrieve-flow-storage-values:
	poetry run dotenv run bash ./scripts/retrieve_flow_storage_values.sh

.PHONY: deploy-bakery
deploy-bakery: setup-remote-state apply configure-kubectl setup-agent retrieve-flow-storage-values

.PHONY: register-flow
register-flow:
	poetry run dotenv run sh -c 'docker run -it --rm \
	-v $$(pwd)/test/recipes/$(flow):/$(flow) \
	-e FLOW_STORAGE_CONNECTION_STRING -e FLOW_STORAGE_CONTAINER -e FLOW_CACHE_CONTAINER -e BAKERY_IMAGE \
    -e PREFECT__CLOUD__AGENT__LABELS -e PREFECT_PROJECT -e PREFECT__CLOUD__AUTH_TOKEN \
    $$BAKERY_IMAGE python3 /$(flow)'

.PHONE: getinfo
getinfo:
	poetry run dotenv run bash ./scripts/get-info.sh $$(pwd)

.PHONE: loki
loki:
	poetry run dotenv run bash ./scripts/loki.sh $$(pwd)

.PHONY: generate-bakery-yaml
generate-bakery-yaml:
	poetry run dotenv run bash ./scripts/generate-yaml.sh
