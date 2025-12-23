#!/bin/bash

# Uninstall kube-prometheus-stack
helm uninstall kube-prometheus-stack --namespace monitoring

# Destroy load generator vm
cd base-steps/4-deploying-automatically-the-load-generator-in-google-cloud/terraform
terraform destroy -var="frontend_ip=${FRONTEND_ADDR:-1.2.3.4}" -auto-approve

# Delete GKE cluster
gcloud container clusters delete shopapp-cluster --zone europe-west6-a --quiet