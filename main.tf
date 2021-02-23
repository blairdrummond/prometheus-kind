terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

variable "ingress_domain" {
  description = "The ingress domain"
  type        = string
  default     = "covid.cloud.statcan.ca"
}


provider "kubernetes" {
  #load_config_file = "true"
  config_path = ".kube/config"
}

provider "helm" {
  kubernetes {
    config_path = ".kube/config"
  }
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"

  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
}


module "monitoring" {
  source = "./namespace/prometheus/"
  namespace = "monitoring"
  ingress_domain = var.ingress_domain
}

#module "local_path_storage" {
#  source = "./namespace/local-path-provisioner/"
#  namespace = "local-path-storage"
#}

module "minio" {
  source = "./namespace/minio/"
  namespace = "minio"
  ingress_domain = var.ingress_domain
}


module "alice" {
  source = "./namespace/jupyter/"
  namespace = "alice"
}


module "bob" {
  source = "./namespace/jupyter/"
  namespace = "bob"
}
