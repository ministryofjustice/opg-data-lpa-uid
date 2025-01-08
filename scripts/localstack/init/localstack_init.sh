#! /usr/bin/env bash

table=$(awslocal dynamodb create-table \
    --table-name lpa-uid-local \
    --key-schema AttributeName=uid,KeyType=HASH \
    --attribute-definitions AttributeName=uid,AttributeType=S AttributeName=source,AttributeType=S \
    --global-secondary-indexes '[
              {
                "IndexName": "source_index",
                "KeySchema": [
                    {"AttributeName":"source","KeyType":"HASH"}
                ],
                "Projection": {
                    "ProjectionType":"ALL"
                },
                "ProvisionedThroughput": {
                    "ReadCapacityUnits": 1,
                    "WriteCapacityUnits": 1
                }
            }]' \
    --billing-mode PAY_PER_REQUEST \
    --region eu-west-1)

replica=$(awslocal dynamodb update-table \
    --table-name lpa-uid-local \
    --replica-updates '[{"Create": {"RegionName": "eu-west-2"}}]' \
    --region eu-west-1)

cd ../../../../scripts/lambda
zip lambda.zip forwarder.py
cd ../../



create_regional_services() {
  REGION=$1
  ID=$2
  export create_case_lambda_arn=$(awslocal lambda create-function \
    --function-name lambda-create-case \
    --runtime python3.11 \
    --zip-file fileb://scripts/lambda/lambda.zip \
    --handler forwarder.handler \
    --role arn:aws:iam::000000000000:role/lpa-uid-local \
    --region $REGION \
    | jq -r '.FunctionArn')

    export create_case_lambda_invoke_arn="arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${create_case_lambda_arn}/invocations"

    envsubst '$create_case_lambda_invoke_arn' < docs/openapi/openapi.yaml > docs/openapi/subbed_openapi.yaml

    export api=$(awslocal apigateway create-rest-api \
      --name "lpauid" \
      --region $REGION \
      --tags '{"_custom_id_":"'$ID'"}')

    export openapi=$(awslocal apigateway put-rest-api \
      --mode overwrite \
      --rest-api-id $ID \
      --region $REGION \
      --body fileb://docs/openapi/subbed_openapi.yaml)

    stage=$(awslocal apigateway create-deployment \
      --rest-api-id $ID \
      --stage-name current \
      --region $REGION)
  }

create_regional_services eu-west-1 lpauid
create_regional_services eu-west-2 lpauid_eu_west_2
