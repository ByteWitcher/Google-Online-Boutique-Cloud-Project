#!/bin/bash
set -e

# Check arguments
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <users> <rate> <run_time>"
  exit 1
fi

USERS="$1"
RATE="$2"
RUN_TIME="$3"

# Get project name and frontend address
export PROJECT_NAME=$(gcloud config get-value project)
export FRONTEND_ADDR=$(kubectl get svc frontend-external -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

SERVICE_ACCOUNT="shopapp-terraform-account@$PROJECT_NAME.iam.gserviceaccount.com"
CREDENTIALS_PATH="advanced_steps/2_performance_evaluation/terraform/credentials/shopapp-terraform-account.json"
VM_NAME=loadgenerator-vm-master
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
    echo "Service account $SERVICE_ACCOUNT already exists"
  fi

  # Create and download service account key
  gcloud iam service-accounts keys create "$CREDENTIALS_PATH" --iam-account "$SERVICE_ACCOUNT"
else
  echo "Credentials file already exists at $CREDENTIALS_PATH"
fi

cd advanced_steps/2_performance_evaluation/terraform

# Initialize and apply Terraform
terraform init 
terraform apply -var="frontend_ip=$FRONTEND_ADDR" -var="users=$USERS" -var="rate=$RATE" -var="run_time=$RUN_TIME" -auto-approve

echo "Waiting for Docker to be installed..."

# Wait for Docker to be installed
until gcloud compute ssh "$VM_NAME" --command \
  "bash -lc 'command -v docker >/dev/null 2>&1'"; do
  sleep 5
done
  

echo "Waiting for locust-master container to start..."

# Wait for container to start
until gcloud compute ssh "$VM_NAME" --command \
  "bash -lc \"sudo docker ps -a --format '{{.Names}}' | grep -q '^locust-master$'\""; do
  sleep 5
done

echo "Waiting for locust-master container to finish..."

# Wait for container to exit
gcloud compute ssh "$VM_NAME" --command "
  sudo docker wait locust-master
"

echo "Locust finished"

# Copy all CSV files locally
gcloud compute scp "$VM_NAME:$REMOTE_DIR/*.csv" "../results/users_$USERS/"

echo "All CSV files copied"

# Destroy Terraform resources
echo "Destroying Terraform resources..."
terraform destroy -var="frontend_ip=$FRONTEND_ADDR" -var="users=$USERS" -var="rate=$RATE" -var="run_time=$RUN_TIME" -auto-approve

echo "Evaluation complete"
