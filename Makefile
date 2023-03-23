SHELL = '/bin/bash'
export TF_WORKSPACE ?= local

up:
	docker-compose build lambda-create-case
	docker-compose up -d localstack

	cd terraform/localstack_account && tflocal init
	cd terraform/localstack_account && tflocal apply -auto-approve
	cd terraform/environment && tflocal init
	cd terraform/environment && tflocal apply -auto-approve

test:
	cd terraform/environment && curl -XPOST $$(TF_WORKSPACE=local tflocal output -raw api_stage_uri)cases -d 'test'

down:
	docker-compose down

run-structurizr:
	docker pull structurizr/lite
	docker run -it --rm -p 8080:8080 -v $(PWD)/docs/architecture/dsl/local:/usr/local/structurizr structurizr/lite

run-structurizr-export:
	structurizr-cli export -workspace $(PWD)/docs/architecture/dsl/local/workspace.json -format mermaid
