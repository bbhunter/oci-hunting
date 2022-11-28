#### Description #################################################################################
#
# Indexes all sensitive IAM policies in an OCI environement (i.e. containing statements with the 'manage' or 'use' verb).
#
####

#! /usr/bin/env/bash

all_iam_policies=($(oci search resource structured-search --query-text "QUERY policy resources" --query 'data.items[*].{name:"display-name",id:"identifier",cid:"compartment-id"}' --output json | jq -r '.[]' | jq -c | sed 's/\s/+/g' | sort))
last_iam_policy_compartment_id=''

echo "-----"
echo "The following IAM policies are sensitive (i.e. contain statements with the 'manage' or 'use' verb):"

for iam_policy in ${all_iam_policies[@]}
do
    iam_policy_name="$(echo $iam_policy | jq -r '.name')"
    iam_policy_id="$(echo $iam_policy | jq -r '.id')"
    iam_policy_compartment_id="$(echo $iam_policy | jq -r '.cid')"
    
    iam_policy_sensitive_statements=$(oci iam policy get --policy-id "$iam_policy_id" | jq -r '.data | ."statements"[]' | grep 'manage\|use')

    if [[ "$iam_policy_sensitive_statements" ]]
    then
        if [[ "$iam_policy_compartment_id" != "$last_iam_policy_compartment_id" ]]
        then
            iam_policy_compartment_name=$(oci iam compartment get --compartment-id "$iam_policy_compartment_id" --query 'data.name' | sed "s/\"//g")
            echo ""
            echo "[*] Compartment: $iam_policy_compartment_name"
        fi

        echo "[**] Policy: $iam_policy_name"
        echo "$iam_policy_sensitive_statements" | sed "s/ allow/\nAllow/gi"
        echo ""
        last_iam_policy_compartment_id="$iam_policy_compartment_id"
    fi    
done
