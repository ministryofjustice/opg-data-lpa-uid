# variable "opg_metrics_api_destination_role" {
#   type        = any
#   description = "IAM role to allow api destination calls to opg-metrics"
# }

variable "log_emitted_events" {
  type        = bool
  description = "Log events emitted to /aws/events/{env}-emitted"
  default     = false
}
