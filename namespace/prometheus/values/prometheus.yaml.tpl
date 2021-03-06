additionalPrometheusRules:
  - name: custom-rules-file
    groups:
      - name: node-alerts.rules
        rules:
        - alert: NodeLowCPU
          expr: avg by(instance,job) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * on(instance,job) group_left(nodename) node_uname_info *100 < 15
          for: 2h
          labels:
            severity: high
          annotations:
            summary: "{{ $labels.nodename }} has low CPU availability at {{ $value }}%"

        - alert: NodeDiskPressure
          expr: kube_node_status_condition{condition="DiskPressure",job="kube-state-metrics",status="true"} == 1
          for: 2m
          labels:
            severity: high
          annotations:
            summary: "{{ $labels.node }} has low disk capacity."

        - alert: NodeMemoryPressure
          expr: kube_node_status_condition{condition="MemoryPressure",job="kube-state-metrics",status="true"} == 1
          for: 2m
          labels:
            severity: high
          annotations:
            summary: "{{ $labels.node }} has low memory."

        - alert: NodeApproachMemoryPressure
          expr: sum without (instance) ((node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes * 100)
            * on(instance,job) group_left(nodename) node_uname_info ) < 15
          for: 2m
          labels:
            severity: high
          annotations:
            summary: 'Node {{ $labels.nodename }} is under memory pressure at {{ printf "%.4f" $value }}% left'

        - alert: NodeApproachDiskPressure
          expr: sum without (instance) ((node_filesystem_avail_bytes / node_filesystem_size_bytes * 100)
            * on(instance,job) group_right() node_uname_info) < 15
          for: 2m
          labels:
            severity: high
          annotations:
            summary: 'Node {{ $labels.nodename }} is under disk pressure at {{ printf "%.4f" $value }}% left'

        - alert: NodeNotReady
          expr: kube_node_status_condition{condition="Ready",job="kube-state-metrics",status="true"} == 0
          for: 2m
          labels:
            severity: high
          annotations:
            summary: "{{ $labels.node }} is not in a Ready state but did not trip a Network or Pressure condition."

      - name: certificates.rules
        rules:
        - alert: SSLCertExpiringSoon
          expr: probe_ssl_earliest_cert_expiry{job="blackbox-exporter-prometheus-blackbox-exporter"} - time() < 86400 * 20
          for: 2m
          labels:
            severity: high
          annotations:
            summary: 'SSL certificate for {{ $labels.instance }} expires in less than 20 days.'

      #Using cAdvisor
      - name: notebook.rules
        rules:
        - alert: NotebookRAMPressure
          expr: container_memory_usage_bytes{container!~".*istio.*", namespace!~"knative.*", namespace=~".*-.*", namespace!="kube-system"} /
            container_spec_memory_limit_bytes{container!~"vault.*", namespace!~".*istio.*", container=~".+", namespace!~"gatekeeper.*", namespace!~"azure.*"}
              *100 > 95 < 200
          for: 2m
          labels:
            severity: high
          annotations:
            summary: 'Memory usage high for container {{ $labels.container }} in namespace {{ $labels.namespace }} at {{ printf "%.4f" $value }}%.'
      - name: minio-alert.rules
        rules:
        - alert: MinioStorageSpaceExhausted
          expr: (disk_storage_used / disk_storage_total) > 0.75
          for: 5m
          labels:
            severity: high
          annotations: #needs to change from instance to say namespace later. Do not want ip addresses anywhere
            summary: "Minio storage space has reached greater than 75% capacity (instance {{ $labels.instance }})
              \nVALUE = {{ $value }}\n  LABELS: {{ $labels }}"

grafana:
  adminPassword: ${prometheus_grafana_password}
  ingress:
    enabled: true
    hosts:
      - grafana.${ingress_domain}
    path: /.*
    annotations:
      kubernetes.io/ingress.class: istio
  grafana.ini:
    auth.ldap:
      enabled: false
  persistence:
    enabled: false
    storageClassName: default
    accessModes: ["ReadWriteOnce"]
    size: 100Gi

prometheus:
  ingress:
    enabled: true
    hosts:
      - prometheus.${ingress_domain}
    paths:
      - /.*
    annotations:
      kubernetes.io/ingress.class: istio
  prometheusSpec:
    alertingEndpoints: #Entries taken from port-forwarding command
      - name: prometheus-operator-alertmanager #previously 'alertmanager'
        namespace: monitoring
        port: 9093 #previously 'web'
    # additionalScrapeConfigs:
    # # for minio, this was generated via `mc admin prometheus generate <alias>`
    #   - job_name: minio-job
    #     bearer_token: "{var.minio_metrics_token}"
    #     metrics_path: /minio/prometheus/metrics
    #     scheme: http
    #     static_configs:
    #       - targets: ['minimal-tenant1-minio.minio:9000']
    #storageSpec:
    #  volumeClaimTemplate:
    #    spec:
    #      accessModes: ["ReadWriteOnce"]
    #      storageClassName: default
    #      resources:
    #        requests:
    #          #storage: 20Gi
    #          storage: 2Gi
    #JIRAB ICP-5726
    externalLabels:
      cluster: k8s-cancentral-02-covid-aks

  additionalServiceMonitors:
    - name: "notebook-metrics"
      selector:
        matchExpressions:
          - {key: notebook-name, operator: Exists}
      namespaceSelector:
        any: true
      endpoints:
        - targetPort: 8888

alertmanager:
  config:
    global:
      resolve_timeout: 5m
      slack_api_url: "${slack_api_url}"
    route:
      group_by: ['alertname', 'namespace']
      group_wait: 2m
      group_interval: 24h
      repeat_interval: 12h
      receiver: black_hole #default for less important notifs, do not clutter
      routes:
      - reciever: 'slack-notifs'
        match:
          severity: high
      - reciever: 'slack-notifs'
        match:
          alerttype: idle

    #basic receiver info
    receivers:
    - name: 'slack-notifs'
      slack_configs:
      - channel: '#daaas-prometheus-alerts'
        send_resolved: true
        text: '<!channel> \nsummary: {{ .CommonAnnotations.summary }}'
    - name: black_hole

    #Inhibit Rules
    inhibit_rules:
      - target_match:
        alertname: 'NodeNotReady'
      - source_match_re:
        alertname: '(NodeDiskPressure|NodeLowCPU|NodeMemoryPressure)'
  ingress:
    enabled: false
    # enabled: true
    hosts:
      - alertmanager.${ingress_domain}
    paths:
      - /.*
    annotations:
      kubernetes.io/ingress.class: istio

  #alertmanagerSpec:
  #  storage:
  #    volumeClaimTemplate:
  #      spec:
  #        accessModes: ["ReadWriteOnce"]
  #        storageClassName: default
  #        resources:
  #          requests:
  #            # storage: 20Gi
  #            storage: 2Gi
