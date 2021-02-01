#variable "prometheus_grafana_password" {
#  description = "Promtheus / Grafana Password"
#  type        = string
#  default     = "password"
#}
#
#variable "prometheus_grafana_username" {
#  description = "Promtheus / Grafana User"
#  type        = string
#  default     = "admin"
#}

# data "template_file" "prometheus_values" {
# 	template = file("./values/prometheus-operator.yml")
#
#   	vars = {
# 	  GRAFANA_SERVICE_ACCOUNT = "grafana"
# 	  GRAFANA_ADMIN_USER = "admin"
# 	  GRAFANA_ADMIN_PASSWORD = var.grafana_password
# 	  INGRESS_DOMAIN = var.ingress_domain
# 	  PROMETHEUS_SVC = "${helm_release.prometheus.name}-server"
# 	  NAMESPACE = var.namespace
# 	}
# }


resource "helm_release" "prometheus-operator" {
  name       = "prometheus-operator"
  chart      = "${path.module}/charts/kube-prometheus-stack"
  namespace = var.namespace

  # values = [
  # 	data.template_file.prometheus_values.rendered
  # ]
}
