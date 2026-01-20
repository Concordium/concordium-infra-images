#!/usr/bin/env bash

set -e

if [ "$#" -ne 1 ]; then
    echo "Usage: \$0 '<json_input>' where json_input is the content written by find_images.sh. The content is \
usually obtained by copying from the slack channel events-mgmt. \
Example format: '{\"Stagenet\":[{\"name\":\"stagenet-v6-3-0-0-concordium-node-00000-x86-64\",\"id\":\"ami-03631f7d6549f62bd\",\"provider\":\"aws\"}]}'"
    exit 1
fi

typeset -A environment_to_project
environment_to_project=(
    Stagenet concordium-stagenet-0
    Testnet concordium-testnet-0
    Mainnet concordium-mainnet-0
    BaseImage concordium-mgmt-0
)

json_input="$1"

echo "$json_input" | jq -r 'to_entries | .[] | .key as $key | .value[] | "\($key) \(.id) \(.provider) \(.region // "null")"' | while read -r line; do
    environment=$(echo "$line" | awk '{print $1}')
    id=$(echo "$line" | awk '{print $2}')
    provider=$(echo "$line" | awk '{print $3}')
    aws_region=$(echo "$line" | awk '{print $4}')
    if [[ "$provider" == "aws" ]]; then
      if [[  "$aws_region" == "null" ]]; then
        echo "Region is not provided for $id"
        exit 2;
      fi
      old_tag_snapshot_ids=$(aws ec2 describe-snapshots --region="$aws_region" --filter "Name=tag:Environment,Values=$environment" --query "Snapshots[? contains(Description, '$id')].SnapshotId" --output text)
      for snapshot_id in $old_tag_snapshot_ids; do
        echo "Marking AMI $id and snapshot $snapshot_id for deletion"
        aws ec2 create-tags --region="$aws_region" --resources "$snapshot_id" "$id" --tags Key=ToBeDeleted,Value=True
      done
      new_tag_snapshot_ids=$(aws ec2 describe-snapshots --region="$aws_region" --filter "Name=tag:concordium:environment,Values=$environment" --query "Snapshots[? contains(Description, '$id')].SnapshotId" --output text)
      for snapshot_id in $new_tag_snapshot_ids; do
        echo "Marking AMI $id and snapshot $snapshot_id for deletion"
        aws ec2 create-tags --region="$aws_region" --resources "$snapshot_id" "$id" --tags Key=ToBeDeleted,Value=True
      done
    elif [[ "$provider" == "gcp" ]]; then
      project_name=${environment_to_project[$environment]}
      if [[ -n "$project_name" ]]; then
        echo "Delete gcp image $id"
        gcloud compute images delete "$id" --project="$project_name" --quiet
      else
        echo "No project mapping for environment: $environment"
      fi
    fi
done

for ami_id in $(aws ec2 describe-images --filters "Name=tag:ToBeDeleted,Values=True" --query "Images[].ImageId" --output text); do
  echo "Deleting AMI $ami_id"
  aws ec2 deregister-image --image-id "$ami_id"
done

for snapshot_id in $(aws ec2 describe-snapshots --filters "Name=tag:ToBeDeleted,Values=True" --query "Snapshots[].SnapshotId" --output text); do
  echo "Deleting aws snapshot $snapshot_id"
  aws ec2 delete-snapshot --snapshot-id "$snapshot_id"
done
