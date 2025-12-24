#!/bin/bash
set -e

RUN_EVALUATION="advanced_steps/2_performance_evaluation/run_evaluation.sh"
RESULTS_CSV="advanced_steps/2_performance_evaluation/experiment_times.csv"

# Write CSV header
echo "experiment,users,rate,run_time,start_utc,end_utc" > "$RESULTS_CSV"

# Define experiments
experiments=(
  "E1,10,1,5m"
  "E2,25,2,5m"
  "E3,50,5,5m"
  "E4,100,10,5m"
  "E5,200,20,5m"
  "E6,300,30,5m"
)

for exp in "${experiments[@]}"; do
  IFS=',' read -r EXP_NAME USERS RATE RUN_TIME <<< "$exp"

  echo "Starting experiment $EXP_NAME"

  # Record start time (UTC)
  START_TIME=$(date -u +"%Y-%m-%d %H:%M:%S")

  # Run the experiment
  bash "$RUN_EVALUATION" "$USERS" "$RATE" "$RUN_TIME"

  # Record end time (UTC)
  END_TIME=$(date -u +"%Y-%m-%d %H:%M:%S")

  # Append to CSV
  echo "$EXP_NAME,$USERS,$RATE,$RUN_TIME,$START_TIME,$END_TIME" >> "$RESULTS_CSV"

  echo "Finished experiment $EXP_NAME"
done

echo "All experiments completed. Results saved to $RESULTS_CSV"
