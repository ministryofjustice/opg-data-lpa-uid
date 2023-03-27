resource "aws_dynamodb_table" "lpa_uid" {
  name             = "lpa-uid-${local.environment_name}"
  billing_mode     = "PROVISIONED"
  hash_key         = "uid"
  
  deletion_protection_enabled = true

  attribute {
    name = "uid"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }
}
