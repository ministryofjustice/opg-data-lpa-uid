variable "opg_metrics_endpoint" {
  type = string
}

variable "opg_metrics_api_destination_role" {
  type        = any
  description = "IAM role to allow api destination calls to opg-metrics"
  nullable    = true
}

variable "aws_cloudwatch_event_bus" {
  type = any
}
