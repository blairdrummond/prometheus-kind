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

module "monitoring" {
  source = "./namespace/prometheus/"
  namespace = "monitoring"
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
