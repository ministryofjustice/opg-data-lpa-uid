SHELL = '/bin/bash'

up:
	docker-compose build lambda-create-case
	docker-compose up -d localstack

	cd terraform/local && terraform init
	cd terraform/local && terraform apply -auto-approve

test:
	cd terraform/local && curl -XPOST $$(terraform output -raw api_stage_uri)cases -d 'test'

down:
	docker-compose down
	rm -rf terraform/local/terraform.state.d
	rm -f terraform/local/terraform.state

run-structurizr:
	docker pull structurizr/lite
	docker run -it --rm -p 8080:8080 -v $(PWD)/docs/architecture/dsl/local:/usr/local/structurizr structurizr/lite

run-structurizr-export:
	structurizr-cli export -workspace $(PWD)/docs/architecture/dsl/local/workspace.json -format mermaid
