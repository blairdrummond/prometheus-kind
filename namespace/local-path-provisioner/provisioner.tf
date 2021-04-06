resource "helm_release" "provisioner" {
  name       = "provisioner"
  namespace  = var.namespace
  chart      = "${path.module}/charts/provisioner/"

  set {
    name  = "namespace"
    value = var.namespace
  }
}
