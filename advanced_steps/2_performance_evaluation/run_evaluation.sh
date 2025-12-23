#!/bin/bash

# Set variables
VM_IP="$1"          # Pass the VM IP as first argument
SSH_KEY="~/.ssh/id_rsa"  # Path to your SSH private key
REMOTE_CSV_PATH="/tmp/results/locust_${USERS:-10}.csv"
LOCAL_DIR="./results"

mkdir -p "$LOCAL_DIR"

echo "Waiting for CSV to be generated on VM ($VM_IP)..."

while true; do
  # Check if the CSV exists on the remote VM
  ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "ubuntu@$VM_IP" "test -f $REMOTE_CSV_PATH"
  
  if [ $? -eq 0 ]; then
    echo "CSV found! Downloading..."
    
    # Copy the CSV locally
    scp -i "$SSH_KEY" "ubuntu@$VM_IP:$REMOTE_CSV_PATH" "$LOCAL_DIR/"
    
    if [ $? -eq 0 ]; then
      echo "CSV successfully downloaded to $LOCAL_DIR"
      break
    else
      echo "Failed to download CSV. Retrying..."
    fi
  else
    echo "CSV not yet present. Sleeping for 15 seconds..."
    sleep 15
  fi
done

# Destroy Terraform deployment
echo "Destroying Terraform deployment..."
terraform destroy -auto-approve

echo "All done!"
