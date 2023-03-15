# 2. Build API Gateway consistently from API specification

Date: 2023-03-15

## Status

Accepted

## Context

We have decided to use AWS API Gateway and deploy with Terraform. We will also be using localstack as a local mirror of AWS resources.

An API Gateway deployment is broken down into lots of separate AWS resources.

Until now, we have configured localstack with a list of `aws` CLI commands in an init file, which means they can drift from the real configuration in Terraform.

## Decision

Instead of configuring each API Gateway resource manually, we will drive its configuration from our OpenAPI spec. This will require adding [some additional markup](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-swagger-extensions-integration.html) to the OpenAPI document to identify how the gateway should connect with AWS Lambda.

We will also use the Terraform configuration to create our localstack resources, rather than maintaining a separate script. This will ensure that our local development environment matches real infrastructure as closely as possible.

## Consequences

These changes should ensure that our API specification, real infrastructure and local development environment are all consistent and clearly defined. Any changes to API structure will immediately be propagated in the local environment, making them easier to detect and test, and will automatically deployed to our infrastucture.
