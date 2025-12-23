#!/bin/bash 

# Get project name and frontend IP address
export PROJECT_NAME=$(gcloud config get-value project)
export FRONTEND_ADDR=$(kubectl get svc frontend-external -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Create service account and assign roles
gcloud iam service-accounts create shopapp-terraform-account
gcloud projects add-iam-policy-binding $PROJECT_NAME --member serviceAccount:shopapp-terraform-account@$PROJECT_NAME.iam.gserviceaccount.com --role roles/editor

# Create and download service account key
mkdir -p base-steps/4-deploying-automatically-the-load-generator-in-google-cloud/terraform/credentials
cd base-steps/4-deploying-automatically-the-load-generator-in-google-cloud/terraform/credentials
gcloud iam service-accounts keys create ./shopapp-terraform-account.json --iam-account shopapp-terraform-account@$PROJECT_NAME.iam.gserviceaccount.com

cd ..

terraform init 

terraform apply -var="frontend_ip=$FRONTEND_ADDR" -auto-approve