#### Description #################################################################################
#
# Indexes all Dynamic groups in an OCI environment with their associated rule sets.
#
####

#! /usr/bin/env/bash

echo "-----"
echo "Overview of all IAM policies and associated rules:"

dynamic_groups=($(oci iam dynamic-group list --all | jq -r '.data[] | {"name","id"}' | jq -c))

for dynamic_group in ${dynamic_groups[@]}
do
    dynamic_group_name="$(echo $dynamic_group | jq -r '.name')"
    dynamic_group_id="$(echo $dynamic_group | jq -r '.id')"
    rule_set="$(oci iam dynamic-group get --dynamic-group-id $dynamic_group_id | jq -r '.data | ."matching-rule"')"
    
    echo "[*] Dynamic group: $dynamic_group_name"
    echo $rule_set | sed "s/.*{ *//" | sed "s/}//g" | sed "s/, /\n/g"
    echo ""
done
