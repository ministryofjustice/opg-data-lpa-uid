# UID service tester

During development or changes to the UID service it can be useful to quickly check if the service is working as intended on deployed infra. This script signs a POST request containing a string body using AWS v4 and logs request and response headers and bodies.

To run:

```bash
go build
aws-vault exec <~/.aws PROFILE NAME> -- go run uid-tester
```

The tool supports custom base URLs and request bodies:

```bash
aws-vault exec <~/.aws PROFILE NAME> -- go run uid-tester -baseUrl=https://new.base.url -body={"some": "json"}
```
