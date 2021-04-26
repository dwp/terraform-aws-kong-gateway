SHELL:=bash

default: help

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: test
test: ## Build, test, and destroy default scenario with Kitchen Terraform
	docker run --rm -e AWS_PROFILE=default -v /etc/ssl/certs/:/usr/local/share/ca-certificates/ -v $(shell pwd):/usr/action -v ~/.ssh:/root/.ssh -v ~/.aws:/root/.aws quay.io/dwp/kitchen-terraform:0.14.7 "test hybrid-external-database --destroy=always" \

.PHONY: build
build: ## Build default scenario with Kitchen Terraform
	@make copy-test-dir ; \
	docker run --rm -e AWS_PROFILE=default -v /etc/ssl/certs/:/usr/local/share/ca-certificates/ -v $(shell pwd):/usr/action -v ~/.ssh:/root/.ssh -v ~/.aws:/root/.aws quay.io/dwp/kitchen-terraform:0.14.7 "test hybrid-external-database converge" \


.PHONY: destroy
destroy: ## Build default scenario with Kitchen Terraform
	docker run --rm -e AWS_PROFILE=default -v /etc/ssl/certs/:/usr/local/share/ca-certificates/ -v $(shell pwd):/usr/action -v ~/.ssh:/root/.ssh -v ~/.aws:/root/.aws quay.io/dwp/kitchen-terraform:0.14.7 "test hybrid-external-database destroy"
	@make delete-test-dir


.PHONY: copy-test-dir
copy-test-dir: ## Copy the test directory to match the unique workspace for Kitchen Terraform
	cp -r test/integration/hybrid_external_database test/integration/hybrid_external_database


.PHONY: delete-test-dir
delete-test-dir: ## Copy the test directory to match the unique workspace for Kitchen Terraform
	rm -rf test/integration/hybrid_external_database
