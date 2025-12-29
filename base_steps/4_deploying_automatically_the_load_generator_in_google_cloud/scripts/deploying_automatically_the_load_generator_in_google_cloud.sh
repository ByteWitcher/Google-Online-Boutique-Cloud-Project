#!/bin/bash 

# Get project name and frontend IP address
export PROJECT_NAME=$(gcloud config get-value project)
export SERVICE_ACCOUNT="shopapp-terraform-account@${PROJECT_NAME}.iam.gserviceaccount.com"
export FRONTEND_ADDR=$(kubectl get svc frontend-external -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

CREDENTIALS_PATH="base_steps/4_deploying_automatically_the_load_generator_in_google_cloud/terraform/credentials/shopapp-terraform-account.json"

# Create credentials directory if it doesn't exist
mkdir -p base_steps/4_deploying_automatically_the_load_generator_in_google_cloud/terraform/credentials

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

cd base_steps/4_deploying_automatically_the_load_generator_in_google_cloud/terraform

# Initialize and apply Terraform
terraform init 
terraform apply -var="frontend_ip=$FRONTEND_ADDR" -auto-approve