#!/bin/bash

# Get the external IP address of the frontend service
export FRONTEND_ADDR=$(kubectl get svc frontend-external -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Copy the load generator files to Cloud Shell
gcloud cloud-shell scp --recurse localhost:./base_steps/3_deploying_the_load_generator_on_a_local_machine/loadgenerator/ cloudshell:~/

# Build and run the load generator in Cloud Shell
gcloud cloud-shell ssh --command "
cd loadgenerator
docker build -t loadgenerator .
docker run --rm -e FRONTEND_ADDR=$FRONTEND_ADDR loadgenerator
"