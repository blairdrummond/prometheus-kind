resource "helm_release" "jupyter" {
  name       = "jupyter"
  namespace  = var.namespace
  chart      = "${path.module}/charts/jupyter/"

  set {
    name  = "namespace"
    value = var.namespace
  }

  set {
    name  = "url"
    value = "/notebook/${var.namespace}/jupyter"
  }
}
