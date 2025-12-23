#!/bin/bash

# Set GCP compute zone to europe-west6-a and create the GKE cluster
gcloud config set compute/zone europe-west6-a
gcloud container clusters create shopapp-cluster
gcloud container clusters get-credentials shopapp-cluster

# Clone the microservices-demo repository
git clone --depth 1 --branch v0 https://github.com/GoogleCloudPlatform/microservices-demo.git

# Chance configurations to reduce resources
cd microservices-demo/kustomize/base
sed -i 's/^\(- loadgenerator\.yaml\)/# \1/' kustomization.yaml
sed -i 's/^\(\s*cpu:\s*\)100m/\150m/' emailservice.yaml
sed -i 's/^\(\s*cpu:\s*\)100m/\150m/' recommendationservice.yaml

cd ../..

kubectl apply -k kustomize/