image:
  repository: bitnami/blackbox-exporter
  tag: 0.18.0
  pullPolicy: IfNotPresent
service:
  labels:
    app: prometheus-blackbox-exporter
    jobLabel: blackbox-exporter
    release: prometheus-operator
pod:
  labels:
    app: prometheus-operator-blackbox-exporter
    release: prometheus-operator
serviceMonitor:
  enabled: true
  defaults:
    labels:
      app: prometheus-operator-blackbox-exporter
      release: prometheus-operator
    interval: 60s
    scrapeTimeout: 60s
    module: http_2xx
%{ if length(target_services) != 0 }
  targets:
  %{ for target in target_services }
    - name: ${target}
      url: "https://${target}.${root_domain}"
  %{ endfor }
%{ endif }
