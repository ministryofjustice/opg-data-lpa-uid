# 5. Use DynamoDB for data storage

Date: 2023-03-22

## Status

Accepted

## Context

In this service we will receive a donor's details, generate a unique identifier, and store them all together. We'll then need to be able to pull back that data from the generated identifier.

We won't be storing any related data: anything related to an applicant's draft will be stored in the drafting service, and anything that the OPG requires to manage the case will be stored in Sirius.

We are already committed to hosting our data using AWS.

## Decision

We will store the data for the service in AWS DynamoDB in on-demand capacity mode. The data will be indexed by the unique identifier we generate.

We will take advantage of DynamoDB's performance, availability and scalability to ensure the service is performant and reliable.

## Consequences

DynamoDB is proprietary technology, which limits our ability to change providers in the future. However, as a NoSQL store it provides a limited API which could be replaced relatively easily.
