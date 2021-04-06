variable "namespace" {
  description = "The Namespace name"
  type        = string
}


# # This already exists
#resource "kubernetes_namespace" "namespace" {
#  metadata {
#    name = var.namespace
#    # labels = {
#    #   istio-injection = "enabled"
#    # }
#  }
#}
