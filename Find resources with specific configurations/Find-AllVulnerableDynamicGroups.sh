#### Description #################################################################################
#
# Indexes all vulnerable Dynamic groups in an OCI environement with their associated IAM policy if any.
#
# Note: the Search API does not support the 'dynamic-group' resource
#
####

#! /usr/bin/env/bash

all_vulnerable_dynamic_groups=()
vulnerable_dynamic_groups_without_iam_policy=()
vulnerable_values=(
    'tag'
)

echo "-----"
echo "The following dynamic groups are vulnerable and associated with the following IAM policies:"

# Gather vulnerable dynamic groups
all_dynamic_groups=($(oci iam dynamic-group list --all | jq -r '.data[] | {"name","id"}' | jq -c))

for dynamic_group in ${all_dynamic_groups[@]}
do
    dynamic_group_name="$(echo $dynamic_group | jq -r '.name')"
    dynamic_group_id="$(echo $dynamic_group | jq -r '.id')"
    rule_set="$(oci iam dynamic-group get --dynamic-group-id "$dynamic_group_id" | jq -r '.data | ."matching-rule"')"

    for vulnerable_value in ${vulnerable_values[@]}
    do
        if [[ $(echo $rule_set | grep "$vulnerable_value") ]]
        then
            all_vulnerable_dynamic_groups+=("$dynamic_group_name")
            break
        fi
    done
done

# For each vulnerable group, find their associated IAM policy
all_iam_policies=($(oci search resource structured-search --query-text "QUERY policy resources" --query 'data.items[*].{name:"display-name",id:"identifier"}' --output json | jq -r '.[]' | jq -c | sed 's/\s/+/g'))
iam_policies_with_statements_for_dynamic_groups=()

for iam_policy in ${all_iam_policies[@]}
do
    iam_policy_name="$(echo $iam_policy | jq -r '.name')"
    iam_policy_id="$(echo $iam_policy | jq -r '.id')"
    has_policy_statements_for_dynamic_groups=$(oci iam policy get --policy-id "$iam_policy_id" | jq -r '.data | ."statements"[]' | grep -iF 'dynamic-group')

    if [[ "$has_policy_statements_for_dynamic_groups" ]]
    then
        iam_policies_with_statements_for_dynamic_groups+=("$iam_policy")
    fi    
done

for vulnerable_dynamic_group in ${all_vulnerable_dynamic_groups[@]}
do
    is_first_associated_policy='True'
    has_vulnerable_dynamic_group_policies='False'

    for iam_policy in ${iam_policies_with_statements_for_dynamic_groups[@]}
    do
        iam_policy_name="$(echo $iam_policy | jq -r '.name')"
        iam_policy_id="$(echo $iam_policy | jq -r '.id')"
        is_policy_associated_with_vulnerable_dynamic_group=$(oci iam policy get --policy-id "$iam_policy_id" | jq -r '.data | ."statements"[]' | grep -iF 'dynamic-group' | grep "$vulnerable_dynamic_group")

        if [[ "$is_policy_associated_with_vulnerable_dynamic_group" ]]
        then
            if [[ "$is_first_associated_policy" == 'True' ]]
            then
                echo "Dynamic group: $vulnerable_dynamic_group"
                is_first_associated_policy='False'
            fi

            has_vulnerable_dynamic_group_policies='True'
            echo "IAM policy: $iam_policy_name"
        else
            vulnerable_dynamic_groups_without_iam_policy+=("$vulnerable_dynamic_group")
        fi
    done

    if [[ "$has_vulnerable_dynamic_group_policies" == 'True' ]]
    then
        echo ""
    fi
done

echo "-----"
echo "The following dynamic groups are vulnerable but are NOT associated with any IAM policy:"
printf '%s\n' "${vulnerable_dynamic_groups_without_iam_policy[@]}" | uniq | sort
