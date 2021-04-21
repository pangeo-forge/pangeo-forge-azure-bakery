.PHONEY: init lint format plan apply destroy configure-kubectl

init:
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

configure-kubectl:
	az aks get-credentials --resource-group $$(terraform -chdir="terraform" output -raw bakery_resource_group_name) --name $$(terraform -chdir="terraform" output -raw bakery_cluster_name)
