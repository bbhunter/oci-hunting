#### Description #################################################################################
#
# Indexes all external IP addresses used by Compute instances in an OCI environment.
#
####

#! /usr/bin/env/bash

all_external_ips=()
all_instances=($(oci search resource structured-search --query-text "QUERY instance resources" --query 'data.items[*].{id:"identifier", name:"display-name", cid: "compartment-id"}' --output json | jq -r '.[]' | jq -c | sed 's/\s/+/g'))
n_total_instances="${#all_instances[@]}"
n_scraped_instances=0

for instance in ${all_instances[@]}
do
    instance_id="$(echo $instance | jq -r '.id')"
    instance_name="$(echo $instance | jq -r '.name')"
    instance_cid="$(echo $instance | jq -r '.cid')"

    (( n_scraped_instances++ ))
    echo "[${n_scraped_instances}/${n_total_instances}] scraping instance: $instance_name"

    all_attached_vnics=($(oci compute vnic-attachment list --compartment-id "$instance_cid" --all --query "data[?\"instance-id\"=='${instance_id}'].\"vnic-id\"" | sed s'/[\[",]//g' | sed -e 's/\]//g'))

    for attached_vnic in ${all_attached_vnics[@]}
    do
        all_external_ips+=($(oci network vnic get --vnic-id "$attached_vnic" --query 'data."public-ip"' --raw-output 2> /dev/null))
    done
done

echo "-----"
echo "Compute instances are exposed on the following external IP addresses:"
printf '%s\n' "${all_external_ips[@]}" | uniq | sort
