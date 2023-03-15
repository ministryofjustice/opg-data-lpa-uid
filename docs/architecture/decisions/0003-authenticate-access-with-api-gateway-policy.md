# 3. Authenticate access with API Gateway Policy

Date: 2023-03-15

## Status

Accepted

## Context

We need some OPG services to be able to communicate with the LPA ID Service, whilst ensuring that it is protected from unauthorised requests.

## Decision

Using an API Gateway resource policy, we will only give specific **IAM roles** access to the API. These roles can be both within the same AWS account and in other accounts.

## Consequences

We will only allow requests from authorised services and provide clear documentation of what roles are needed to access the API.

By using AWS services, we are tying ourselves to AWS but taking advantage of existing reliable technology rather than building our own.
