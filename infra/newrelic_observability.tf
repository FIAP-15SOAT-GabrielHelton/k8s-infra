# Dashboard e alertas — provider Terraform `newrelic`. Fica neste repositório
# (infraestrutura observacional) mesmo consultando dados de outros apps
# (api, auth-serverless): o dashboard/alerta não pertence a quem gera o dado,
# só observa o que já foi enviado ao New Relic por eles.

resource "newrelic_one_dashboard" "oficina_mecanica" {
  name = "Oficina Mecanica — Observabilidade"

  page {
    name = "Negocio — Ordens de Servico"

    widget_bar {
      title  = "Volume diario de OS abertas"
      row    = 1
      column = 1
      width  = 6
      height = 3

      nrql_query {
        query = "SELECT count(*) FROM Transaction WHERE name = 'Controller/api/v1/work_orders/create' FACET dateOf(timestamp) SINCE 30 days ago"
      }
    }

    widget_line {
      title  = "Tempo medio de execucao por etapa (minutos)"
      row    = 1
      column = 7
      width  = 6
      height = 3

      nrql_query {
        query = "SELECT average(duration_minutes) FROM WorkOrderStageDuration FACET stage TIMESERIES 1 day SINCE 30 days ago"
      }
    }

    widget_bar {
      title  = "Falhas no processamento de OS/orcamentos por use case"
      row    = 4
      column = 1
      width  = 6
      height = 3

      nrql_query {
        query = "SELECT count(*) FROM UseCaseFailed WHERE use_case LIKE 'WorkOrders::%' OR use_case LIKE 'Quotes::%' FACET use_case SINCE 7 days ago"
      }
    }

    widget_line {
      title  = "Erros e falhas nas integracoes (transacoes com erro)"
      row    = 4
      column = 7
      width  = 6
      height = 3

      nrql_query {
        query = "SELECT count(*) FROM TransactionError TIMESERIES 1 hour SINCE 1 day ago"
      }
    }
  }

  page {
    name = "Infraestrutura"

    widget_line {
      title  = "Latencia media das APIs"
      row    = 1
      column = 1
      width  = 6
      height = 3

      nrql_query {
        query = "SELECT average(duration) * 1000 AS 'Latencia (ms)' FROM Transaction TIMESERIES 1 hour SINCE 1 day ago"
      }
    }

    widget_billboard {
      title  = "Uptime do healthcheck (/up)"
      row    = 1
      column = 7
      width  = 6
      height = 3

      nrql_query {
        query = "SELECT percentage(count(*), WHERE error IS false) AS 'Uptime %' FROM Transaction WHERE name = 'Controller/rails/health/show' SINCE 1 day ago"
      }
    }

    widget_line {
      title  = "Consumo de CPU do cluster (cores)"
      row    = 4
      column = 1
      width  = 6
      height = 3

      nrql_query {
        query = "SELECT average(cpuUsedCores) FROM K8sPodSample FACET podName TIMESERIES 1 hour SINCE 1 day ago"
      }
    }

    widget_line {
      title  = "Consumo de memoria do cluster (bytes)"
      row    = 4
      column = 7
      width  = 6
      height = 3

      nrql_query {
        query = "SELECT average(memoryUsedBytes) FROM K8sPodSample FACET podName TIMESERIES 1 hour SINCE 1 day ago"
      }
    }
  }
}

# --- Alertas ---

resource "newrelic_alert_policy" "oficina_mecanica" {
  name                = "Oficina Mecanica"
  incident_preference = "PER_CONDITION"
}

resource "newrelic_notification_destination" "email" {
  name = "oficina-mecanica-email"
  type = "EMAIL"

  property {
    key   = "email"
    value = var.new_relic_alert_email
  }
}

resource "newrelic_notification_channel" "email" {
  name           = "oficina-mecanica-email-channel"
  type           = "EMAIL"
  destination_id = newrelic_notification_destination.email.id
  product        = "IINT"

  property {
    key   = "subject"
    value = "Alerta Oficina Mecanica: {{issueTitle}}"
  }
}

resource "newrelic_workflow" "oficina_mecanica" {
  name                  = "oficina-mecanica-alerts"
  muting_rules_handling = "NOTIFY_ALL_ISSUES"

  issues_filter {
    name = "filter-oficina-mecanica-policy"
    type = "FILTER"

    predicate {
      attribute = "labels.policyIds"
      operator  = "EXACTLY_MATCHES"
      values    = [newrelic_alert_policy.oficina_mecanica.id]
    }
  }

  destination {
    channel_id = newrelic_notification_channel.email.id
  }
}

# Falhas no processamento de ordens de servico/orcamentos (exigido pelo tech challenge).
resource "newrelic_nrql_alert_condition" "work_order_failures" {
  policy_id                    = newrelic_alert_policy.oficina_mecanica.id
  name                         = "Falhas no processamento de OS/orcamentos"
  type                         = "static"
  enabled                      = true
  violation_time_limit_seconds = 3600

  nrql {
    query = "SELECT count(*) FROM UseCaseFailed WHERE use_case LIKE 'WorkOrders::%' OR use_case LIKE 'Quotes::%'"
  }

  critical {
    operator              = "above"
    threshold             = 5
    threshold_duration    = 300
    threshold_occurrences = "at_least_once"
  }

  fill_option = "none"
}

# Latencia elevada nas APIs.
resource "newrelic_nrql_alert_condition" "high_latency" {
  policy_id                    = newrelic_alert_policy.oficina_mecanica.id
  name                         = "Latencia elevada da API"
  type                         = "static"
  enabled                      = true
  violation_time_limit_seconds = 3600

  nrql {
    query = "SELECT average(duration) FROM Transaction"
  }

  critical {
    operator              = "above"
    threshold             = 2
    threshold_duration    = 300
    threshold_occurrences = "all"
  }

  fill_option = "none"
}

# Healthcheck/uptime — queda de disponibilidade do endpoint /up.
resource "newrelic_nrql_alert_condition" "low_uptime" {
  policy_id                    = newrelic_alert_policy.oficina_mecanica.id
  name                         = "Disponibilidade baixa (healthcheck /up)"
  type                         = "static"
  enabled                      = true
  violation_time_limit_seconds = 3600

  nrql {
    query = "SELECT percentage(count(*), WHERE error IS false) FROM Transaction WHERE name = 'Controller/rails/health/show'"
  }

  critical {
    operator              = "below"
    threshold             = 90
    threshold_duration    = 300
    threshold_occurrences = "all"
  }

  fill_option = "none"
}
