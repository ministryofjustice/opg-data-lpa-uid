variable "opg_metrics_api_destination_role" {
  type        = any
  description = "IAM role to allow api destination calls to opg-metrics"
}

variable "opg_metrics_api_destination_arn" {
  type        = string
  description = "ARN for API destination"
}
