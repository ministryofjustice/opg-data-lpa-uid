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

    export api_id=$(awslocal apigateway import-rest-api \
      --region $REGION \
      --body fileb://docs/openapi/subbed_openapi.yaml \
      | jq -r '.id')

    stage=$(awslocal apigateway create-deployment \
      --rest-api-id $api_id \
      --stage-name local \
      --region $REGION)

    echo "$api_id"
  }

export eu_west_1_id=$(create_regional_services eu-west-1)
export eu_west_2_id=$(create_regional_services eu-west-2)

cat << EOF > ./scripts/localstack/init/localstack_api_urls.json
{"eu_west_1_url": "http://${eu_west_1_id}.execute-api.localhost.localstack.cloud:4566/local", "eu_west_2_url": "http://${eu_west_2_id}.execute-api.localhost.localstack.cloud:4566/local"}
EOF
