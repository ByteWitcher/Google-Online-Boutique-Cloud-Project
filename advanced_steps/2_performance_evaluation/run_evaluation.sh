#!/bin/bash
set -e

# Check arguments
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <users> <run_time>"
  exit 1
fi

USERS="$1"
RUN_TIME="$2"

# Get project name
export PROJECT_NAME=$(gcloud config get-value project)

SERVICE_ACCOUNT="shopapp-terraform-account@$PROJECT_NAME.iam.gserviceaccount.com"
CREDENTIALS_PATH="advanced_steps/2_performance_evaluation/terraform/credentials/shopapp-terraform-account.json"
VM_NAME=loadgenerator-vm
REMOTE_DIR="/tmp/results"

# Create credentials and local results directories
mkdir -p advanced_steps/2_performance_evaluation/terraform/credentials
mkdir -p "advanced_steps/2_performance_evaluation/results/users_$USERS"

# Check if credentials file exists
if [ ! -f "$CREDENTIALS_PATH" ]; then
  # Check if service account exists
  if ! gcloud iam service-accounts describe "$SERVICE_ACCOUNT" >/dev/null 2>&1; then
    # Create service account and assign roles
    gcloud iam service-accounts create shopapp-terraform-account
    gcloud projects add-iam-policy-binding "$PROJECT_NAME" --member "serviceAccount:$SERVICE_ACCOUNT" --role roles/editor
  else
    echo "Service account $SERVICE_ACCOUNT already exists."
  fi

  # Create and download service account key
  gcloud iam service-accounts keys create "$CREDENTIALS_PATH" --iam-account "$SERVICE_ACCOUNT"
else
  echo "Credentials file already exists at $CREDENTIALS_PATH"
fi

cd advanced_steps/2_performance_evaluation/terraform

# Initialize and apply Terraform
terraform init 
terraform apply -var="frontend_ip=$FRONTEND_ADDR" -var="users=$USERS" -var="run_time=$RUN_TIME" -auto-approve

# Wait until at least one CSV exists on VM
echo "Waiting for CSV files to be generated on VM..."
while ! gcloud compute ssh "$VM_NAME" --command "ls $REMOTE_DIR/*.csv" >/dev/null 2>&1; do
  sleep 5
done

echo "CSV files found! Copying to local machine..."

# Copy all CSV files locally
gcloud compute scp "$VM_NAME:$REMOTE_DIR/*.csv" "../results/users_$USERS/"

echo "All CSV files copied"

# Destroy Terraform resources
echo "Destroying Terraform resources..."
terraform destroy -var="frontend_ip=$FRONTEND_ADDR" -var="users=$USERS" -var="run_time=$RUN_TIME" -auto-approve

echo "Evaluation complete!"
