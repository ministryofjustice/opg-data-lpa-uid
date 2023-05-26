moved {
  from = module.eu-west-1.aws_dynamodb_table.lpa_uid[0]
  to   = module.global.aws_dynamodb_table.lpa_uid
}

moved {
  from = module.eu-west-1.aws_kms_alias.dynamodb_alias
  to   = module.global.aws_kms_alias.dynamodb_alias_eu_west_1
}

moved {
  from = module.eu-west-2.aws_kms_alias.dynamodb_alias
  to   = module.global.aws_kms_alias.dynamodb_alias_eu_west_2
}
moved {
  from = module.eu-west-1.aws_kms_key.dynamodb
  to   = module.global.aws_kms_key.dynamodb
}
