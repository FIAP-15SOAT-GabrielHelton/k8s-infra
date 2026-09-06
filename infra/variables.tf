variable "new_relic_license_key" {
  description = "Ingest License Key da conta New Relic (usada pelo agente de infraestrutura do cluster)"
  type        = string
  sensitive   = true
}

variable "new_relic_account_id" {
  description = "Account ID da conta New Relic"
  type        = string
}

variable "new_relic_api_key" {
  description = "User API Key da conta New Relic (usada pelo provider Terraform para criar dashboard/alertas)"
  type        = string
  sensitive   = true
}

variable "new_relic_region" {
  description = "Região da conta New Relic (US ou EU)"
  type        = string
  default     = "US"
}

variable "new_relic_alert_email" {
  description = "E-mail que recebe as notificações da policy de alertas do New Relic"
  type        = string
}
