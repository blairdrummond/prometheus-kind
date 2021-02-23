Read through this

https://learn.hashicorp.com/tutorials/terraform/kubernetes-provider?in=terraform/use-case


Install, `terraform`, `helm`, `kubectl`, and `kubectl krew`. And probably `jq` and `yq`.

Prometheus Operator
===================

Note, you need to grab the chart dependencies

  .. code-block:: bash

    cd namespace/prometheus
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm dependency update
    helm dependency build

    # Terrafoo
    terraform init
    terraform apply


    # Install krew
    # https://krew.sigs.k8s.io/docs/user-guide/setup/install/
    # This is needed for installing the MinIO operator.

    # Install the minio operator
    make minio
