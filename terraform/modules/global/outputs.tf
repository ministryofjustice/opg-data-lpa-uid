output "lambda_iam_role" {
  value = aws_iam_role.lambda
}

output "opg_metrics_iam_role" {
  value = aws_iam_role.opg_metrics
}
