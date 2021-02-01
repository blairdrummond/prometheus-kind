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