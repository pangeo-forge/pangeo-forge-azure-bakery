.PHONY: init
init:
	./scripts/init.sh

.PHONY: install
install: loki
	./scripts/install.sh

.PHONY: destroy
destroy:
	./scripts/destroy.sh

.PHONY: test
test:
	./scripts/test.sh

.PHONE: getinfo
getinfo:
	poetry run dotenv run bash ./scripts/get-info.sh $$(pwd)

.PHONE: loki
loki:
	poetry run dotenv run bash ./scripts/loki.sh $$(pwd)

.PHONY: generate-bakery-yaml
generate-bakery-yaml:
	poetry run dotenv run bash ./scripts/generate-yaml.sh

.PHONY: service-principal
service-principal:
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
