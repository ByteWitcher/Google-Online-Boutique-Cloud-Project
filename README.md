# Project Execution Guide

This repository contains all the scripts and resources required to reproduce the experiments conducted for this project. The workflow is fully automated and organized into clearly defined steps, allowing to reproduce the complete setup and evaluation process with minimal manual intervention.

---

## Prerequisites

Before running any script, ensure that the following tools are installed and properly configured on your system:

- **Google Cloud SDK (`gcloud`)**
- **kubectl**
- **Terraform**
- **Helm**
- **Git**
- **Python 3**

Additionally, make sure that:

- You are authenticated with Google Cloud (`gcloud auth login`)
- A valid GCP project is selected (`gcloud config set project <PROJECT_ID>`)
- Billing is enabled for the project

---

## Project Structure

All scripts are organized by logical steps corresponding to the project workflow.
Each step is fully automated and can be executed independently **as long as prerequisite steps have been completed**.

```
.
├── advanced_steps
│   ├── 1_monitoring_the_application_and_the_infrastructure
│   ├── 2_performance_evaluation
│   └── 3_canary_releases
├── base_steps
│   ├── 1_deploying_the_original_application_in_gke
│   ├── 3_deploying_the_load_generator_on_a_local_machine
│   └── 4_deploying_automatically_the_load_generator_in_google_cloud
```

Each step directory contains:

- A `scripts/` folder with executable automation scripts
- Configuration files (Terraform, Kubernetes manifests, etc.)
- Generated outputs or results (where applicable)

---

## How to Run the Project

All scripts **must be executed from the root of the repository**.
Do **not** run them from inside subdirectories.

Each step is executed via a single script whose name matches the step name.

### Example: Deploying the Load Generator Automatically

To execute the step _“Deploying the load generator automatically in Google Cloud”_, run:

```bash
bash base_steps/4_deploying_automatically_the_load_generator_in_google_cloud/scripts/deploying_automatically_the_load_generator_in_google_cloud.sh
```

---

## Execution Order and Dependencies

Some steps depend on the successful completion of previous ones.
For example:

- `3_deploying_the_load_generator_on_a_local_machine` and `4_deploying_automatically_the_load_generator_in_google_cloud`
  **require** that the Kubernetes cluster has already been created which is done in `1_deploying_the_original_application_in_gke`.

Therefore, steps **must be executed in order**, following their numbering.

---

## Notes and Best Practices

- All scripts assume execution from the **root of the repository**.
- Do **not** modify relative paths unless you fully understand the dependency structure.
- Some steps provision cloud resources that incur cost; remember to run the cleanup scripts when finished.
- Logs and generated artifacts (e.g., CSV performance data) are stored within their respective step directories.

---

## Cleanup

To remove all deployed resources and avoid unnecessary cloud costs, execute:

```bash
bash cleanup.sh
```

This script deletes all cloud resources created during the experiments, including virtual machines, Kubernetes clusters, and auxiliary infrastructure.
