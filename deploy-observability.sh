#!/bin/bash
set -e

export KUBECONFIG=$PWD/kubeconfig.yaml

if ! command -v helm &> /dev/null; then
    echo ">>> Helm not found on host. Installing Helm locally..."
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    HELM_INSTALL_DIR=$PWD bash get_helm.sh --no-sudo
    export PATH=$PWD:$PATH
fi

echo ">>> Creating observability namespace..."
kubectl create namespace observability --dry-run=client -o yaml | kubectl apply -f -

echo ">>> Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update

echo ">>> Deploying Prometheus..."
helm upgrade --install prometheus prometheus-community/prometheus \
  --namespace observability \
  --set alertmanager.enabled=false \
  --set pushgateway.enabled=false \
  --set server.persistentVolume.enabled=false

echo ">>> Deploying Tempo..."
helm upgrade --install tempo grafana/tempo \
  --namespace observability \
  --set traces.otlp.grpc.enabled=true \
  --set traces.otlp.http.enabled=true

echo ">>> Deploying Grafana..."
helm upgrade --install grafana grafana/grafana \
  --namespace observability \
  --set persistence.enabled=false \
  --set service.type=NodePort \
  --set service.nodePort=30002 \
  -f manifests/observability/grafana-datasources.yaml

echo ">>> Deploying OpenTelemetry Collector..."
helm upgrade --install otel-collector open-telemetry/opentelemetry-collector \
  --namespace observability \
  -f manifests/observability/otel-values.yaml

echo "======================================================"
echo ">>> Observability Stack Deployed successfully!"
echo ">>> Grafana is available at http://<VM_IP>:30002"
echo ">>> Username: admin"
echo ">>> Password can be retrieved with:"
echo "kubectl get secret --namespace observability grafana -o jsonpath=\"{.data.admin-password}\" | base64 --decode ; echo"
echo "======================================================"
