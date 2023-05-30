output "lambda_iam_role" {
  value = aws_iam_role.lambda
}

output "dynamodb_table" {
  value = aws_dynamodb_table.lpa_uid
}

output "dynamodb_table_replica" {
  value = aws_dynamodb_table_replica.lpa_uid_eu_west_2
}
