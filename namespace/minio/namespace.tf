variable "ingress_domain" {
  type    = string
  default = "covid.cloud.statcan.ca"
}

variable "namespace" {
  description = "The Namespace name"
  type        = string
}

resource "kubernetes_namespace" "namespace" {
  metadata {
    name = var.namespace
    # labels = {
    #   istio-injection = "enabled"
    # }
  }
}
