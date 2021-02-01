# root_domain + target_services get templated into the
# blackbox exporter's targets as:
#
# targets:
#   - name: ${target}
#     url: https://${target}.${root_domain}
#
variable "ingress_domain" {
  type    = string
  default = "covid.cloud.statcan.ca"
}

variable "target_services" {
    default = [
        "grafana",
        "kubeflow",
        "minio-standard-tenant-1",
        "minio-premium-tenant-1",
        "shiny"
    ]
}

locals {
    blackbox_values = templatefile("${path.module}/values/blackbox.yaml.tpl", {
        target_services = var.target_services,
        root_domain = var.ingress_domain
    })
}

resource "helm_release" "blackbox-exporter" {
  name       = "blackbox-exporter"
  namespace  = var.namespace
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-blackbox-exporter"
  version    = "4.10.0"

  values = [ local.blackbox_values ]
}
