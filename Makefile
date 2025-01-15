GOLANGCI_LINT_VERSION ?= v1.60.3
default: help

.PHONY: build-go-img
export BUILDKIT_PROGRESS=plain
export IMG_REGISTRY=docker.io
export IMG_REPO=development2018/dp-golang
export IMG_TAG=local
export PLATFORM=linux/amd64
build-go-img: ## Build the dp-go image
	@ docker buildx build --platform ${PLATFORM}  applications/golang -f applications/golang/Dockerfile -t ${IMG_REGISTRY}/${IMG_REPO}:${IMG_TAG}

.PHONY: build-php-img
export BUILDKIT_PROGRESS=plain
export IMG_REGISTRY=docker.io
export IMG_REPO=development2018/dp-php
export IMG_TAG=local
export PLATFORM=linux/amd64
build-php-img: ## Build the dp-php image
	@ docker buildx build --platform ${PLATFORM}  applications/php -f applications/php/Dockerfile -t ${IMG_REGISTRY}/${IMG_REPO}:${IMG_TAG}

.PHONY: push-fresh-images
push-fresh-images: # Push images over to docker hub
	@ docker push docker.io/development2018/dp-php:local
 	@ docker push docker.io/development2018/dp-golang:local

.PHONY: kube-auth
kube-auth: # Setup kubectl kubeconfig with aws
	@ aws eks update-kubeconfig --region eu-north-1 --name dp-prod-eu-north-1 --role-arn arn:aws:iam::019496914213:role/dp-terraform-access

.PHONY: help
help: ## this help
	@ awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m\t%s\n", $$1, $$2 }' $(MAKEFILE_LIST) | column -s$$'\t' -t
