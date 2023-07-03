SHELL = '/bin/bash'

build:
	docker-compose build --parallel lambda-create-case delegator

up:
	docker-compose up -d localstack

	cd terraform/local && terraform init
	cd terraform/local && terraform apply -auto-approve

test-api-eu-west-1 test-api-eu-west-2:
	cd terraform/local && curl \
		-XPOST $$(terraform output -raw api_stage_uri_$(REGION))cases \
		-H 'Content-type:application/json' \
		-d '{"source":"APPLICANT","type":"hw","donor":{"name":"Jack Rubik","dob":"1938-03-18","postcode":"W8A0IK"}}'
	@echo ""

	cd terraform/local && curl \
		$$(terraform output -raw api_stage_uri_$(REGION))health
	@echo ""

test-api-eu-west-1: REGION=eu_west_1
test-api-eu-west-2: REGION=eu_west_2

test-api: test-api-eu-west-1 test-api-eu-west-2

test:
	go test -count 1 ./lambda/create-case/...

down:
	docker-compose down
	rm -rf terraform/local/terraform.tfstate.d
	rm -f terraform/local/terraform.state
	rm -f terraform/local/terraform.state.backup

run-structurizr:
	docker pull structurizr/lite
	docker run -it --rm -p 8080:8080 -v $(PWD)/docs/architecture/dsl/local:/usr/local/structurizr structurizr/lite

run-structurizr-export:
	docker pull structurizr/cli:latest
	docker run --rm -v $(PWD)/docs/architecture/dsl/local:/usr/local/structurizr structurizr/cli \
	export -workspace /usr/local/structurizr/workspace.dsl -format mermaid

get-item:
	docker-compose exec localstack \
		awslocal dynamodb get-item --table-name lpa-uid-local --key '{"uid":{"S":"$(UID)"}}' --region eu-west-1

scan:
	docker-compose exec localstack \
		awslocal dynamodb scan --table-name lpa-uid-local --region eu-west-1
