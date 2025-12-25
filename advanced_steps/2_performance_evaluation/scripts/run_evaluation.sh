#!/bin/bash
set -e

# Check arguments
if [ "$#" -ne 5 ]; then
  echo "Usage: $0 <master_ip_address> <num_workers> <users> <rate> <run_time>"
  exit 1
fi

export FRONTEND_ADDR=$(kubectl get svc frontend-external -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
MASTER_IP_ADDRESS="$1"
NUM_WORKERS="$2"
USERS="$3"
RATE="$4"
RUN_TIME="$5"
VM_MASTER_NAME=loadgenerator-vm-master
VM_WORKER_NAME=loadgenerator-vm-worker-
REMOTE_DIR="/tmp/results"

# Create local results directory
mkdir -p "advanced_steps/2_performance_evaluation/results/users_$USERS"

echo "Starting evaluation: users=$USERS, rate=$RATE, run_time=$RUN_TIME"

# Run loadgenerator containers on worker VMs

for i in $(seq 1 "$NUM_WORKERS"); do
  WORKER_NAME="${VM_WORKER_NAME}${i}"
  echo "Starting loadgenerator container on worker VM $WORKER_NAME..."

  gcloud compute ssh "$WORKER_NAME" --command "
  sudo docker run -d --rm \
    --name locust-worker \
    -e MASTER_IP_ADDRESS=$MASTER_IP_ADDRESS \
    loadgenerator
  "
done

# Run loadgenerator container on master VM

echo "Starting loadgenerator container on master VM..."

gcloud compute ssh "$VM_MASTER_NAME" --command "
  sudo docker run -d --name locust-master --rm -p 5557:5557 -e FRONTEND_ADDR=$FRONTEND_ADDR -e USERS=$USERS -e RATE=$RATE -e RUN_TIME=$RUN_TIME \
  -v /tmp/results:/tmp/results loadgenerator > /tmp/docker-output.log 2>&1
  sudo docker wait locust-master
"
echo "Locust finished"

# Copy all CSV files locally
gcloud compute scp "$VM_MASTER_NAME:$REMOTE_DIR/*.csv" "advanced_steps/2_performance_evaluation/results/users_$USERS/"

gcloud compute ssh "$VM_MASTER_NAME" --command "
  sudo rm -f $REMOTE_DIR/*
"

echo "All CSV files copied"


echo "Evaluation completed for users=$USERS, rate=$RATE, run_time=$RUN_TIME"