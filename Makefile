SHELL = '/bin/bash'

up:
	docker-compose build --parallel lambda-create-case delegator
	docker-compose up -d localstack

	cd terraform/local && terraform init
	cd terraform/local && terraform apply -auto-approve

test-api:
	cd terraform/local && curl \
		-XPOST $$(terraform output -raw api_stage_uri)cases \
		-H 'Content-type:application/json' \
		-d '{"source":"APPLICANT","type":"hw","donor":{"name":"Jack Rubik","dob":"1938-03-18","postcode":"W8A0IK"}}'

test:
	go test ./lambda/create-case/...

down:
	docker-compose down
	rm -rf terraform/local/terraform.tfstate.d
	rm -f terraform/local/terraform.state

run-structurizr:
	docker pull structurizr/lite
	docker run -it --rm -p 8080:8080 -v $(PWD)/docs/architecture/dsl/local:/usr/local/structurizr structurizr/lite

run-structurizr-export:
	docker pull structurizr/cli:latest
	docker run --rm -v $(PWD)/docs/architecture/dsl/local:/usr/local/structurizr structurizr/cli \
	export -workspace /usr/local/structurizr/workspace.dsl -format mermaid
