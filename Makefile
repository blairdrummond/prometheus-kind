PROJECT_NAME := monitoring-test


.PHONY: clean kind

all: clean _build
	@echo Done

##########################################
###     Kind setup (k8s in docker)     ###
##########################################
# Instructions here:
# https://learn.hashicorp.com/tutorials/terraform/kubernetes-provider?in=terraform/use-case

kind-config.yaml:
	curl https://raw.githubusercontent.com/hashicorp/learn-terraform-deploy-nginx-kubernetes-provider/master/kind-config.yaml \
		--output kind-config.yaml

delete:
	kind delete clusters $(PROJECT_NAME)

kind:  kind-config.yaml
	mkdir -p .kube
	# Note that we're using .kube/config , NOT ~/.kube/config.
	kind create cluster \
		--name $(PROJECT_NAME) \
		--config kind-config.yaml \
		--kubeconfig .kube/config

kubectl-setup:
	kubectl cluster-info --context kind-$(PROJECT_NAME)
