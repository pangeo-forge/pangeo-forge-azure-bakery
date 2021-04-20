.PHONEY: install lint format plan apply destroy

install:
	terraform -chdir="terraform/" init

lint:
	terraform -chdir="terraform/" validate

format:
	terraform -chdir="terraform/" fmt

plan:
	terraform -chdir="terraform/" plan -var-file="../deployment.tfvars.json"

apply:
	terraform -chdir="terraform/" apply -auto-approve -var-file="../deployment.tfvars.json"

destroy:
	terraform -chdir="terraform/" destroy -auto-approve -var-file="../deployment.tfvars.json"
