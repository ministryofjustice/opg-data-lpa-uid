output "lambda_iam_role" {
  value = aws_iam_role.lambda
}

output "dynamodb_table" {
  value = aws_dynamodb_table.lpa_uid
}
