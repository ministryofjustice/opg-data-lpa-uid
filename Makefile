SHELL = '/bin/bash'

build:
	docker compose build --parallel lambda-create-case

up:
	docker compose up -d --wait localstack

generate:
	git ls-files | grep '.*/mock_.*_test\.go' | xargs rm -f
	go tool mockery

test-api-eu-west-1 test-api-eu-west-2:
	curl \
		-XPOST $(URL)/cases \
		-H 'Content-type:application/json' \
		-d '{"source":"APPLICANT","type":"personal-welfare","donor":{"name":"Jack Rubik","dob":"1938-03-18","postcode":"W8A0IK"}}'
	@echo ""

	curl \
		$(URL)/health
	@echo ""

test-api-eu-west-1: URL=http://lpauid.execute-api.localhost.localstack.cloud:4566/current
test-api-eu-west-2: URL=http://lpauid_eu_west_2.execute-api.localhost.localstack.cloud:4566/current

test-api:
	@SUCCESS=false; \
	COUNT=0; \
	while [ $${SUCCESS} == false ] && [ $${COUNT} -lt 6 ]; do \
		docker inspect -f {{.State.Health.Status}} lpa-uid-localstack | grep -q healthy; \
		if [ $$? -eq 0 ]; then \
			SUCCESS=true; \
		else \
			echo "Localstack not healthy, retrying in 10 seconds"; \
			COUNT=`expr $$COUNT + 1`; \
			sleep 10; \
		fi; \
		if [ $$COUNT -eq 6 ]; then \
			echo "Localstack was not healthy in time"; \
			exit 1; \
		fi \
	done; \
	make test-api-eu-west-1 test-api-eu-west-2

test:
	go test -count 1 ./lambda/create-case/... ./internal/...

down:
	docker compose down

run-structurizr:
	docker pull structurizr/lite
	docker run -it --rm -p 8080:8080 -v $(PWD)/docs/architecture/dsl/local:/usr/local/structurizr structurizr/lite

run-structurizr-export:
	docker pull structurizr/cli:latest
	docker run --rm -v $(PWD)/docs/architecture/dsl/local:/usr/local/structurizr structurizr/cli \
	export -workspace /usr/local/structurizr/workspace.dsl -format mermaid

get-item:
	docker compose exec localstack \
		awslocal dynamodb get-item --table-name lpa-uid-local --key '{"uid":{"S":"$(UID)"}}' --region eu-west-1

scan:
	docker compose exec localstack \
		awslocal dynamodb scan --table-name lpa-uid-local --region eu-west-1
