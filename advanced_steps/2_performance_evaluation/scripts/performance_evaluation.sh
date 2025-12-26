#!/bin/bash

set -e

export PROJECT_NAME=$(gcloud config get-value project)
VM_MASTER_NAME=loadgenerator-vm-master
VM_WORKER_NAME=loadgenerator-vm-worker-
SERVICE_ACCOUNT="shopapp-terraform-account@$PROJECT_NAME.iam.gserviceaccount.com"
CREDENTIALS_PATH="advanced_steps/2_performance_evaluation/terraform/credentials/shopapp-terraform-account.json"
RUN_EVALUATION="advanced_steps/2_performance_evaluation/scripts/run_evaluation.sh"
RESULTS_CSV="advanced_steps/2_performance_evaluation/results/experiment_times.csv"

# Define experiments
experiments=(
  "E1,10,1,5m"
  "E2,25,2,5m"
  "E3,50,5,5m"
  "E4,100,10,5m"
  "E5,200,20,5m"
  "E6,300,30,5m"
  "E7,400,40,5m"
  "E8,500,50,5m"
  "E9,600,60,5m"
  "E10,700,70,5m"
  "E11,800,80,5m"
  "E12,900,90,5m"
  "E13,1000,100,5m"
  "E14,1500,150,5m"
  "E15,2000,200,5m"
  "E16,5000,500,5m"
  "E17,10000,1000,5m"
)

# Create credentials and results directories if they don't exist
mkdir -p advanced_steps/2_performance_evaluation/terraform/credentials
mkdir -p advanced_steps/2_performance_evaluation/results

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
terraform apply -auto-approve

MASTER_IP_ADDRESS=$(terraform output master_ip_address)
NUM_WORKERS=$(terraform output num_workers)

echo "Waiting for docker to be installed on master VM..."

until gcloud compute ssh "$VM_MASTER_NAME" --command "bash -lc 'command -v docker >/dev/null 2>&1'"; do
  sleep 5
done

for i in $(seq 1 "$NUM_WORKERS"); do
  WORKER_NAME="${VM_WORKER_NAME}${i}"
  echo "Waiting for docker to be installed on worker VM $WORKER_NAME..."
  
  until gcloud compute ssh "$WORKER_NAME" --command "bash -lc 'command -v docker >/dev/null 2>&1'"; do
    sleep 5
  done
done

echo "Waiting for image to be built on master VM..."

until gcloud compute ssh "$VM_MASTER_NAME" --command "bash -lc 'sudo docker images | grep loadgenerator >/dev/null 2>&1'"; do
  sleep 5
done

for i in $(seq 1 "$NUM_WORKERS"); do
  WORKER_NAME="${VM_WORKER_NAME}${i}"
  echo "Waiting for image to be built on worker VM $WORKER_NAME..."
  
  until gcloud compute ssh "$WORKER_NAME" --command "bash -lc 'sudo docker images | grep loadgenerator >/dev/null 2>&1'"; do
    sleep 5
  done
  
  echo "Image is built on worker VM $WORKER_NAME."
done

cd -

# Write CSV header only if file does not exist or is empty
if [ ! -f "$RESULTS_CSV" ] || [ ! -s "$RESULTS_CSV" ]; then
  echo "experiment,users,rate,run_time,start_utc,end_utc" > "$RESULTS_CSV"
else
  echo "Results CSV already exists, appending new experiments"
fi


for exp in "${experiments[@]}"; do
  IFS=',' read -r EXP_NAME USERS RATE RUN_TIME <<< "$exp"

  echo "Starting experiment $EXP_NAME"

  # Record start time (UTC)
  START_TIME=$(date -u +"%Y-%m-%d %H:%M:%S")

  # Run the experiment
  bash "$RUN_EVALUATION" "$MASTER_IP_ADDRESS" "$NUM_WORKERS" "$USERS" "$RATE" "$RUN_TIME"

  # Record end time (UTC)
  END_TIME=$(date -u +"%Y-%m-%d %H:%M:%S")

  # Append to CSV
  echo "$EXP_NAME,$USERS,$RATE,$RUN_TIME,$START_TIME,$END_TIME" >> "$RESULTS_CSV"

  echo "Finished experiment $EXP_NAME"
done

echo "All experiments completed. Results saved to $RESULTS_CSV"

# Destroy Terraform resources
cd advanced_steps/2_performance_evaluation/terraform
terraform destroy -auto-approve


# Generate plots
cd -
mkdir -p advanced_steps/2_performance_evaluation/results/plots

if [ ! -d advanced_steps/2_performance_evaluation/venv ]; then
  python3 -m venv advanced_steps/2_performance_evaluation/venv
  source advanced_steps/2_performance_evaluation/venv/bin/activate
  pip install --upgrade pip
  pip install -r advanced_steps/2_performance_evaluation/requirements.txt
else
  source advanced_steps/2_performance_evaluation/venv/bin/activate
fi

python3 advanced_steps/2_performance_evaluation/plot/plot_locust_results.py

deactivate