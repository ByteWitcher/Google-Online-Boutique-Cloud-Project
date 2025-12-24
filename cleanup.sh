#!/bin/bash

# Uninstall kube-prometheus-stack
helm uninstall kube-prometheus-stack --namespace monitoring

# Delete GKE cluster
gcloud container clusters delete shopapp-cluster --zone europe-west6-a --quiet