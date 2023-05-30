moved {
  from = module.global.aws_dynamodb_table.lpa_uid
  to   = module.eu-west-1.aws_dynamodb_table.lpa_uid[0]
}

moved {
  from = module.global.aws_dynamodb_table_replica.lpa_uid_eu_west_2
  to   = module.eu-west-2.aws_dynamodb_table_replica.lpa_uid[0]
}

###

moved {
  from = module.global.aws_kms_key.dynamodb
  to   = module.eu-west-1.aws_kms_key.dynamodb[0]
}

moved {
  to   = module.eu-west-2.aws_kms_replica_key.dynamodb[0]
  from = module.global.aws_kms_replica_key.dynamodb_eu_west_2[0]
}


###


moved {
  from = module.global.aws_kms_alias.dynamodb_alias_eu_west_1
  to   = module.eu-west-1.aws_kms_alias.dynamodb_alias_eu_west_1[0]
}

moved {
  from = module.global.aws_kms_alias.dynamodb_alias_eu_west_2[0]
  to   = module.eu-west-1.aws_kms_alias.dynamodb_alias
}



#  module.global.aws_dynamodb_table_replica.lpa_uid_eu_west_2
