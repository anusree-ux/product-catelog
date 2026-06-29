#!/bin/bash

set -e

CLUSTER_NAME="devops-lab"

echo "========================================"
echo " Bootstrapping Kind Kubernetes Cluster"
echo "========================================"

echo ""
echo "Checking prerequisites..."

command -v docker >/dev/null || { echo "Docker is not installed."; exit 1; }
command -v kind >/dev/null || { echo "Kind is not installed."; exit 1; }
command -v kubectl >/dev/null || { echo "kubectl is not installed."; exit 1; }
command -v helm >/dev/null || { echo "Helm is not installed."; exit 1; }

echo ""
echo "Creating Kind cluster..."

kind delete cluster --name ${CLUSTER_NAME} || true

kind create cluster \
  --name ${CLUSTER_NAME} \
  --config kubernetes/kind-config.yaml

echo ""
echo "Loading application images..."

docker build -t product-api:v1 ./backend
docker build -t product-web:v1 ./frontend

kind load docker-image product-api:v1 --name ${CLUSTER_NAME}
kind load docker-image product-web:v1 --name ${CLUSTER_NAME}

echo ""
echo "Installing ingress-nginx..."

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx >/dev/null 2>&1 || true
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx \
    --create-namespace

echo ""
echo "Installing Prometheus & Grafana..."

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update

helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --create-namespace

echo ""
echo "Installing Loki..."

helm repo add grafana https://grafana.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update

helm upgrade --install loki grafana/loki \
    --namespace logging \
    --create-namespace

echo ""
echo "Installing Promtail..."

helm upgrade --install loki-promtail grafana/promtail \
    --namespace logging

echo ""
echo "Deploying application..."

kubectl apply -k kubernetes/k8s/overlays/dev

echo ""
echo "Applying Network Policies..."

kubectl apply -f kubernetes/k8s/base/network/

echo ""
echo "Waiting for deployments..."

kubectl wait \
  --for=condition=Available \
  deployment/postgres \
  --timeout=300s

kubectl wait \
  --for=condition=Available \
  deployment/api \
  --timeout=300s

kubectl wait \
  --for=condition=Available \
  deployment/web \
  --timeout=300s

echo ""
echo "========================================"
echo " Deployment Successful"
echo "========================================"

echo ""
kubectl get pods

echo ""
kubectl get svc

echo ""
kubectl get ingress

echo ""
echo "Application:"
echo "http://localhost"

echo ""
echo "API:"
echo "http://localhost/api/products"

echo ""
echo "Grafana:"
echo "kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring"

echo ""
echo "Prometheus:"
echo "kubectl port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090 -n monitoring"
