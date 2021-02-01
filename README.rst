Read through this

https://learn.hashicorp.com/tutorials/terraform/kubernetes-provider?in=terraform/use-case


Prometheus Operator
===================

Note, you need to grab the chart dependencies

  .. code-block:: bash

    cd namespace/prometheus
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm dependency update
    helm dependency build
