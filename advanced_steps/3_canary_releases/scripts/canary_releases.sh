#!/bin/bash
set -euo pipefail

# 1) Resize cluster (if needed)
# 2) Install istioctl and enable sidecar injection
# 3) Deploy frontend v1 and v2 (manifests are in ../frontend.yaml)
# 4) Apply Istio canary split (../istio-canary.yaml)
# 5) Install Prometheus and Kiali (for metrics and UI)
# 6) Optionally shift all traffic to v2

CLUSTER_NAME="${CLUSTER_NAME:-shopapp-cluster}"
ZONE="${ZONE:-europe-west6-a}"
ISTIO_VERSION="${ISTIO_VERSION:-1.18.0}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
MICRO_DIR="${PROJECT_ROOT}/microservices-demo"
FRONTEND_SRC="${MICRO_DIR}/src/frontend"
FRONTEND_MANIFEST="${BASE_DIR}/frontend.yaml"
ISTIO_MANIFEST="${BASE_DIR}/istio-canary.yaml"
PROJECT_ID="${REGISTRY_PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}"

echo "[1/9] Ensuring kubectl context and resizing cluster to 4 nodes..."
gcloud container clusters get-credentials "${CLUSTER_NAME}" --zone "${ZONE}" --quiet || true
gcloud container clusters resize "${CLUSTER_NAME}" --node-pool=default-pool --num-nodes=4 --zone="${ZONE}" --quiet

echo "[2/9] Installing istioctl ${ISTIO_VERSION} (if not already on PATH)..."
if ! command -v istioctl >/dev/null 2>&1; then
  curl -L https://istio.io/downloadIstio | ISTIO_VERSION="${ISTIO_VERSION}" sh -
  export PATH="$PATH:$(pwd)/istio-${ISTIO_VERSION}/bin"
fi

echo "[3/9] Installing Istio demo profile and enabling sidecar injection..."
istioctl install --set profile=demo -y
kubectl label namespace default istio-injection=enabled --overwrite

echo "[4/9] Preparing frontend v2: small source change, build and push image..."
if [[ -z "${PROJECT_ID}" ]]; then
  echo "ERROR: Could not determine GCP project ID. Set REGISTRY_PROJECT_ID or configure gcloud." >&2
  exit 1
fi

# Apply a simple, visible change to the UI title (idempotent)
HEADER_HTML="${FRONTEND_SRC}/templates/header.html"
if [[ -f "${HEADER_HTML}" ]]; then
  if ! grep -q "Online Boutique (v2)" "${HEADER_HTML}"; then
    sed -i 's/Online Boutique/Online Boutique (v2)/' "${HEADER_HTML}"
  fi
else
  echo "ERROR: header.html not found at ${HEADER_HTML}" >&2
  exit 1
fi

# Build and push the v2 image
pushd "${FRONTEND_SRC}" >/dev/null
gcloud auth configure-docker gcr.io -q
docker build -t "gcr.io/${PROJECT_ID}/frontend:v2" .
docker push "gcr.io/${PROJECT_ID}/frontend:v2"
popd >/dev/null

# Ensure the manifest references the image we just pushed
sed -i -E "s#gcr\.io/[a-z0-9-]+/frontend:v2#gcr.io/${PROJECT_ID}/frontend:v2#g" "${FRONTEND_MANIFEST}"

echo "[5/9] Deleting original single-version frontend Deployment (if present)..."
kubectl delete deployment frontend --ignore-not-found

echo "[6/9] Applying frontend v1/v2 deployments and services..."
kubectl apply -f "${FRONTEND_MANIFEST}"
kubectl rollout status deployment/frontend-v1 --timeout=300s
kubectl rollout status deployment/frontend-v2 --timeout=300s

echo "[7/9] Applying Istio canary split (initial weights from istio-canary.yaml)..."
kubectl apply -f "${ISTIO_MANIFEST}"

echo "[8/9] Installing Kiali (requires Prometheus metrics); installing Prometheus first..."
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.28/samples/addons/prometheus.yaml
kubectl wait --for=condition=available --timeout=600s deployment/prometheus -n istio-system
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/kiali.yaml
kubectl wait --for=condition=available --timeout=600s deployment/kiali -n istio-system
echo "Kiali installed. To view the dashboard, run: kubectl -n istio-system port-forward svc/kiali 20001:20001"

echo "[9/9] (Optional) Shift all traffic to frontend v2..."
read -r -p "Do you want to route 100% of traffic to v2 now? [y/N]: " CONFIRM
if [[ "${CONFIRM}" =~ ^[Yy]$ ]]; then
  TMP_VS="$(mktemp)"
  # Replace weights: set v2 to 100, v1 to 0
  sed 's/weight: 25/weight: 100/' "${ISTIO_MANIFEST}" | \
    sed 's/weight: 75/weight: 0/' > "${TMP_VS}"
  kubectl apply -f "${TMP_VS}"
  rm -f "${TMP_VS}"
  echo "Applied full cutover to v2."
else
  echo "Skipping full cutover. Canary split remains as defined in istio-canary.yaml."
fi

echo "Done."
