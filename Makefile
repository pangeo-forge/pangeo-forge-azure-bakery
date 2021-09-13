#Composite Steps
.PHONY: deploy
deploy: deploy-cluster loki

#Individual Steps
.PHONY: init
init:
	./scripts/check-prereqs.sh
	./scripts/init.sh

.PHONY: deploy-cluster
deploy-cluster:
	./scripts/check-prereqs.sh
	./scripts/deploy.sh

.PHONY: destroy
destroy:
	./scripts/check-prereqs.sh
	./scripts/destroy.sh

.PHONY: test-flow
test-flow:
	./scripts/check-prereqs.sh
	./scripts/test-flow.sh

.PHONY: loki
loki: deploy
	poetry run dotenv run bash ./scripts/loki.sh $$(pwd)

.PHONY: get-cluster-creds
get-cluster-creds:
	poetry run dotenv run bash ./scripts/k8s-connect.sh

.PHONE: getinfo
getinfo:
	poetry run dotenv run bash ./scripts/get-info.sh $$(pwd)

.PHONY: generate-bakery-yaml
generate-bakery-yaml:
	./scripts/check-prereqs.sh
	poetry run dotenv run bash ./scripts/generate-yaml.sh

.PHONY: service-principal
service-principal:
	./scripts/check-prereqs.sh
	./scripts/sp-setup.sh

.PHONY: lint
lint:
	./scripts/lint.sh

.PHONY: setup-remote-state
setup-remote-state:
	poetry run dotenv run bash ./scripts/setup_remote_state.sh

.PHONY: destroy-remote-state
destroy-remote-state:
	poetry run dotenv run sh -c 'az group delete --resource-group $$TF_VAR_identifier-bakery-remote-state-resource-group --yes'

.PHONY: get-grafana-admin
get-grafana-admin:
	./scripts/check-prereqs.sh
	./scripts/get-grafana-admin.sh
