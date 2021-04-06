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
	rm -f terraform.tfstate terraform.tfstate.backup

setup: kind krew
	echo "Done setup."

kind:  kind-config.yaml
	mkdir -p .kube
	# Note that we're using .kube/config , NOT ~/.kube/config.
	kind create cluster \
		--name $(PROJECT_NAME) \
		--config kind-config.yaml \
		--kubeconfig .kube/config

	# # Create the pvc provisioner
	helm template ./manual/provisioner | kubectl --kubeconfig .kube/config apply -f -

kubectl-setup:
	kubectl cluster-info --context kind-$(PROJECT_NAME)

minio:
	KUBECONFIG=.kube/config PATH=$$HOME/.krew/bin:$$PATH \
		kubectl krew update || true

	KUBECONFIG=.kube/config PATH=$$HOME/.krew/bin:$$PATH \
		kubectl krew install minio || true

	KUBECONFIG=.kube/config PATH=$$HOME/.krew/bin:$$PATH \
		kubectl minio init || true

	KUBECONFIG=.kube/config PATH=$$HOME/.krew/bin:$$PATH \
		kubectl create namespace minio-tenant-1 || true

	KUBECONFIG=.kube/config PATH=$$HOME/.krew/bin:$$PATH \
		kubectl minio tenant create minio-tenant-1 \
		--servers 1            \
		--volumes 4            \
		--capacity 5Gi         \
		--namespace minio-tenant-1 \
		--storage-class local-path | tee minio-creds.txt

	# The operator was using an out-of-date console image,
	# So needed to patch it.
	kubectl --kubeconfig .kube/config \
		-n minio-tenant-1 patch tenants.minio.min.io minio-tenant-1 \
		--type='json' -p='[{"op": "replace", "path": "/spec/console/image", "value":"minio/console:v0.6.2"}]'

	# http only, please
	kubectl --kubeconfig .kube/config \
		-n minio-tenant-1 patch tenants.minio.min.io minio-tenant-1 \
		--type='json' -p='[{"op": "replace", "path": "/spec/requestAutoCert", "value":false}]'

minio-secrets:
	@printf 'MINIO_ACCESS_KEY=%s\nMINIO_SECRET_KEY=%s\n' \
		$$(kubectl --kubeconfig .kube/config -n minio-tenant-1 get secrets minio-tenant-1-creds-secret -o yaml \
			| yq -r '.data[] | @base64d' | tr '\n' ' ')
minio-add-local:
	mc config host add local http://localhost:9000 \
		$$(kubectl --kubeconfig .kube/config -n minio-tenant-1 get secrets minio-tenant-1-creds-secret -o yaml \
			| yq -r '.data[] | @base64d' | tr '\n' ' ')

minio-metrics-token: minio-add-local
	mc admin prometheus generate local

plan apply:
	test -n "$$TF_VAR_slack_api_url"
	terraform $@
