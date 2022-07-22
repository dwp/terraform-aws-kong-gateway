SHELL:=bash

default: help

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: bootstrap
bootstrap: ## Bootstrap local environment for first use
	@make git-hooks

.PHONY: git-hooks
git-hooks: ## Set up hooks in .githooks
	@git submodule update --init .githooks ; \
	git config core.hooksPath .githooks \

.PHONY: test
test: ## Build, test, and destroy default scenario with Kitchen Terraform
	docker run --rm -e AWS_PROFILE=default -v $(shell pwd):/usr/action -v ~/.aws:/root/.aws -v /etc/ssl/certs/:/usr/local/share/ca-certificates/ quay.io/dwp/kitchen-terraform:0.14.7 "test default --destroy=always"

.PHONY: test-hybrid-external-database
test-hybrid-external-database: ## Build, test, and destroy hybrid-external-database scenario with Kitchen Terraform
	docker run --rm -e AWS_PROFILE=default -v $(shell pwd):/usr/action -v ~/.aws:/root/.aws -v /etc/ssl/certs/:/usr/local/share/ca-certificates/ quay.io/dwp/kitchen-terraform:0.14.7 "test hybrid-external-database --destroy=always"

.PHONY: build
build: ## Build default scenario with Kitchen Terraform
	docker run --rm -e AWS_PROFILE=default -v $(shell pwd):/usr/action -v ~/.aws:/root/.aws -v /etc/ssl/certs/:/usr/local/share/ca-certificates/ quay.io/dwp/kitchen-terraform:0.14.7 "test default converge"

.PHONY: build-al
build-al: ## Build default scenario with Kitchen Terraform
	docker run --rm -e AWS_PROFILE=default -v $(shell pwd):/usr/action -v ~/.aws:/root/.aws -v /etc/ssl/certs/:/usr/local/share/ca-certificates/ quay.io/dwp/kitchen-terraform:0.14.7 "converge hybrid-amazon-linux"

.PHONY: verify-al
verify-al: ## Build default scenario with Kitchen Terraform
	docker run --rm -e AWS_PROFILE=default -v $(shell pwd):/usr/action -v ~/.aws:/root/.aws -v /etc/ssl/certs/:/usr/local/share/ca-certificates/ quay.io/dwp/kitchen-terraform:0.14.7 "verify hybrid-amazon-linux"

.PHONY: destroy-al
destroy-al: ## Build default scenario with Kitchen Terraform
	docker run --rm -e AWS_PROFILE=default -v $(shell pwd):/usr/action -v ~/.aws:/root/.aws -v /etc/ssl/certs/:/usr/local/share/ca-certificates/ quay.io/dwp/kitchen-terraform:0.14.7 "destroy hybrid-amazon-linux"

.PHONY: test-al
test-al: ## Build default scenario with Kitchen Terraform
	docker run --rm -e AWS_PROFILE=default -v $(shell pwd):/usr/action -v ~/.aws:/root/.aws -v /etc/ssl/certs/:/usr/local/share/ca-certificates/ quay.io/dwp/kitchen-terraform:0.14.7 "test hybrid-amazon-linux --destroy=always"

.PHONY: build-ecs
build-ecs: ## Build ecs scenario with Kitchen Terraform
	docker run --rm -e AWS_PROFILE=default -v $(shell pwd):/usr/action -v ~/.aws:/root/.aws -v /etc/ssl/certs/:/usr/local/share/ca-certificates/ quay.io/dwp/kitchen-terraform:0.14.7 "converge hybrid-ecs"

.PHONY: verify-ecs
verify-ecs: ## Build ecs scenario with Kitchen Terraform
	docker run --rm -e AWS_PROFILE=default -v $(shell pwd):/usr/action -v ~/.aws:/root/.aws -v /etc/ssl/certs/:/usr/local/share/ca-certificates/ quay.io/dwp/kitchen-terraform:0.14.7 "verify hybrid-ecs"

.PHONY: destroy-ecs
destroy-ecs: ## Build ecs scenario with Kitchen Terraform
	docker run --rm -e AWS_PROFILE=default -v $(shell pwd):/usr/action -v ~/.aws:/root/.aws -v /etc/ssl/certs/:/usr/local/share/ca-certificates/ quay.io/dwp/kitchen-terraform:0.14.7 "destroy hybrid-ecs"

.PHONY: test-ecs
test-ecs: ## Build ecs scenario with Kitchen Terraform
	docker run --rm -e AWS_PROFILE=default -v $(shell pwd):/usr/action -v ~/.aws:/root/.aws -v /etc/ssl/certs/:/usr/local/share/ca-certificates/ quay.io/dwp/kitchen-terraform:0.14.7 "test hybrid-ecs --destroy=always"

.PHONY: build-hybrid-external-database
build-hybrid-external-database: ## Test hybrid-external-database scenario with Kitchen Terraform
	docker run --rm -e AWS_PROFILE=default -v $(shell pwd):/usr/action -v ~/.aws:/root/.aws -v /etc/ssl/certs/:/usr/local/share/ca-certificates/ quay.io/dwp/kitchen-terraform:0.14.7 "converge hybrid-external-database"

.PHONY: destroy
destroy: ## Build default scenario with Kitchen Terraform
	docker run --rm -e AWS_PROFILE=default -v $(shell pwd):/usr/action -v ~/.aws:/root/.aws -v /etc/ssl/certs/:/usr/local/share/ca-certificates/ quay.io/dwp/kitchen-terraform:0.14.7 "test default destroy"

.PHONY: destroy-hybrid-external-database
destroy-hybrid-external-database: ## Test hybrid-external-database scenario with Kitchen Terraform
	docker run --rm -e AWS_PROFILE=default -v $(shell pwd):/usr/action -v ~/.aws:/root/.aws -v /etc/ssl/certs/:/usr/local/share/ca-certificates/ quay.io/dwp/kitchen-terraform:0.14.7 "destroy hybrid-external-database"
