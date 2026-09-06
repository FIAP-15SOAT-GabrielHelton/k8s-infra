# Integração New Relic Kubernetes — coleta CPU/memória do cluster (nodes e pods)
# e o estado dos objetos K8s (deployments, HPA), exigido pelo tech challenge.
# Mantido enxuto (só newrelic-infrastructure + kube-state-metrics) para caber
# nos recursos limitados do AWS Academy — logging/kubeEvents/pixie desligados.
resource "helm_release" "newrelic_bundle" {
  name             = "newrelic-bundle"
  repository       = "https://helm-charts.newrelic.com"
  chart            = "nri-bundle"
  namespace        = "newrelic"
  create_namespace = true
  version          = "8.0.22"

  set {
    name  = "global.licenseKey"
    value = var.new_relic_license_key
  }

  set {
    name  = "global.cluster"
    value = aws_eks_cluster.main.name
  }

  set {
    name  = "newrelic-infrastructure.privileged"
    value = "true"
  }

  set {
    name  = "kube-state-metrics.enabled"
    value = "true"
  }

  set {
    name  = "kubeEvents.enabled"
    value = "false"
  }

  set {
    name  = "logging.enabled"
    value = "false"
  }

  set {
    name  = "prometheus.enabled"
    value = "false"
  }

  set {
    name  = "newrelic-pixie.enabled"
    value = "false"
  }

  depends_on = [aws_eks_node_group.main]
}
