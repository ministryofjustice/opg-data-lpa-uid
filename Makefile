run-structurizr:
	docker pull structurizr/lite
	docker run -it --rm -p 8080:8080 -v $(PWD)/docs/architecture/dsl/local:/usr/local/structurizr structurizr/lite

run-structurizr-export:
	structurizr-cli export -workspace $(PWD)/docs/architecture/dsl/local/workspace.json -format mermaid
