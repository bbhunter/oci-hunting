#### Description #################################################################################
#
# Indexes all Object Storage Buckets in an OCI environement and determines whether they are publicly accessible.
#
####

#! /usr/bin/env/bash

all_publicly_accessible_buckets=()
all_buckets=($(oci search resource structured-search --query-text "QUERY bucket resources" --query 'data.items[*].{id:"identifier", name:"display-name", cid: "compartment-id"}' --output json | jq -r '.[]' | jq -c | sed 's/\s/+/g'))
n_total_buckets="${#all_buckets[@]}"
n_scraped_buckets=0

for bucket in ${all_buckets[@]}
do
    bucket_id="$(echo $bucket | jq -r '.id')"
    bucket_name="$(echo $bucket | jq -r '.name')"
    bucket_cid="$(echo $bucket | jq -r '.cid')"

    (( n_scraped_buckets++ ))
    echo "[${n_scraped_buckets}/${n_total_buckets}] scraping bucket: $bucket_name"

    bucket_public_access="$(oci os bucket get --bucket-name "$bucket_name" | jq -r '.data | ."public-access-type"')"

    if [[ "$bucket_public_access" != 'NoPublicAccess' ]]
    then
        bucket_compartment_name=$(oci iam compartment get --compartment-id "$bucket_cid" --query 'data.name' | sed "s/\"//g")
        all_publicly_accessible_buckets+=("${bucket_compartment_name}/${bucket_name}")
    fi
done

echo "-----"
echo "The following Cloud Storage buckets are publicly accessible:"
printf '%s\n' "${all_publicly_accessible_buckets[@]}" | uniq | sort
