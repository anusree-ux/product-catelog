#!/bin/bash
set -euo pipefail

CLUSTER_NAME="devops-lab"
LOG_FILE="bootstrap-$(date +%s).log"

# -----------------------------
# Resolve project root (IMPORTANT FIX)
# -----------------------------
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# -----------------------------
# Logging
# -----------------------------
log() {
  echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

fail() {
  log "❌ ERROR: $1"
  exit 1
}

# -----------------------------
# SAFE retry (NO eval)
# -----------------------------
retry() {
  local max=$1
  shift

  for i in $(seq 1 "$max"); do
    log "🔁 Attempt $i/$max: $*"
    if "$@"; then
      return 0
    fi
    sleep 5
  done

  fail "Command failed after $max attempts: $*"
}

trap 'fail "Script failed at line $LINENO"' ERR

# -----------------------------
# Cleanup for port-forward
# -----------------------------
cleanup() {
  log "🧹 Cleaning up background processes"
  kill "${PF_PID:-}" 2>/dev/null || true
}
trap cleanup EXIT

# -----------------------------
log "🚀 Starting Kind Bootstrap"

command -v docker >/dev/null || fail "Docker missing"
command -v kind >/dev/null || fail "Kind missing"
command -v kubectl >/dev/null || fail "kubectl missing"
command -v helm >/dev/null || fail "Helm missing"

# -----------------------------
# Cluster reset
# -----------------------------
log "🧹 Deleting old cluster"
kind delete cluster --name "$CLUSTER_NAME" || true

log "📦 Creating cluster"
kind create cluster --name "$CLUSTER_NAME" --config kubernetes/kind-config.yaml

retry 10 kubectl wait --for=condition=Ready nodes --all --timeout=120s

# -----------------------------
# Build images (ROOT FIX APPLIED)
# -----------------------------
log "🔨 Building backend"
docker build -t product-catalog-backend:v1 "$ROOT_DIR/backend"

log "🔨 Building frontend"
docker build -t product-catalog-frontend:v1 "$ROOT_DIR/frontend"

log "📦 Loading images into Kind"
kind load docker-image product-catalog-backend:v1 --name "$CLUSTER_NAME"
kind load docker-image product-catalog-frontend:v1 --name "$CLUSTER_NAME"

# -----------------------------
# Namespaces
# -----------------------------
log "📁 Creating namespaces"
kubectl create ns monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl create ns logging --dry-run=client -o yaml | kubectl apply -f -

# -----------------------------
# Ingress
# -----------------------------
log "🌐 Installing ingress-nginx"

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx >/dev/null || true
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=NodePort \
  --set controller.service.nodePorts.http=30080 \
  --set controller.service.nodePorts.https=30443

retry 20 kubectl rollout status deployment -n ingress-nginx ingress-nginx-controller --timeout=120s

# -----------------------------
# Monitoring
# -----------------------------
log "📊 Installing monitoring stack"

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null || true
helm repo update

helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace

retry 30 kubectl wait --for=condition=Ready pods -n monitoring --all --timeout=180s

# -----------------------------
# Deploy apps
# -----------------------------
log "🚀 Deploying applications"
kubectl apply -k "$ROOT_DIR/kubernetes/k8s/overlays/dev"

retry 20 kubectl rollout status deployment/api --timeout=120s
retry 20 kubectl rollout status deployment/web --timeout=120s
retry 20 kubectl rollout status deployment/postgres --timeout=120s

# -----------------------------
# Validate endpoints
# -----------------------------
log "🔎 Checking endpoints"
retry 10 kubectl get endpoints api | grep -q api
retry 10 kubectl get endpoints web | grep -q web

# -----------------------------
# Ingress functional test (FIXED)
# -----------------------------
log "🌐 Testing ingress"

kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8080:80 >/dev/null 2>&1 &
PF_PID=$!

sleep 5

retry 10 curl -sf -H "Host: localhost" http://localhost:8080/api/health
retry 10 curl -sf -H "Host: localhost" http://localhost:8080/api/products

# -----------------------------
# Final status
# -----------------------------
log "📡 Cluster status"
kubectl get nodes | tee -a "$LOG_FILE"
kubectl get pods -A | tee -a "$LOG_FILE"
kubectl get svc -A | tee -a "$LOG_FILE"
kubectl get ingress -A | tee -a "$LOG_FILE"

log "========================================"
log "🎉 BOOTSTRAP SUCCESSFUL"
log "========================================"

log "🌍 App: http://localhost"
log "🌍 API: http://localhost/api/products"
log "📊 Grafana: kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring"
log "📈 Prometheus: kubectl port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090 -n monitoring"

log "📝 Log file: $LOG_FILE"
