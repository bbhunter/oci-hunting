# One-liner

Collection of one-liners to find OCI resources with specific configurations. 


## User capabilities

### List what capabilities each user has in the tenancy

```shell
oci iam user list --query 'data[].{".User Account can generate:": "name", "API Keys": capabilities."can-use-api-keys", "Auth Tokens": capabilities."can-use-auth-tokens", "Secret key": capabilities."can-use-customer-secret-keys", "DB creds": capabilities."can-use-db-credentials", "OAuth 2.0 creds": capabilities."can-use-auth2-client-credentials", "SMTP creds": capabilities."can-use-smtp-credentials"}' --output table --all
```

## OCI resources

### List all the compartment where a specific type of resource is deployed (e.g. bucket, instance)

```shell
for compartment_id in $(oci search resource structured-search --query-text "QUERY <RESOURCE-TYPE> resources" | jq -r '.data | .items[] | ."compartment-id"' | sort | uniq); do oci iam compartment get --compartment-id "$compartment_id" --query 'data.name' | sed "s/\"//g"; done | sort
```
