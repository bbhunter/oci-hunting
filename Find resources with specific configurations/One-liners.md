# One-liner

Collection of one-liners to find OCI resources with specific configurations. 


## Getting an overview

### List all types of resource currently deployed in the environment, across all compartments

`Known issue:` some resources type will be missing, as not all types of resources are supported by the Search API (e.g. bucket)

```shell
oci search resource structured-search --query-text "QUERY all resources where lifeCycleState != 'TERMINATED' && lifeCycleState != 'FAILED'" | jq -r '.data | .items[] | ."resource-type"' | sort | uniq
```


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
