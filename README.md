# Observability Sidecar Demo: The Evolution of a Legacy App

This project demonstrates the modernization of a legacy microservices application by incrementally introducing observability through sidecar proxies. We use the **Weaveworks Sock Shop** as our baseline "legacy" application and progressively inject different sidecars to observe the evolution of network metrics, tracing, and visibility without altering the application code.

## The Narrative and Stages

We explore four distinct phases of observability:

1. **Phase 1: The Baseline (Legacy)**
   - **Architecture:** Raw microservices communicating directly.
   - **Observability:** Basic node-level and pod-level metrics (CPU, Memory). No visibility into L7 traffic or distributed tracing.
2. **Phase 2: HAProxy**
   - **Architecture:** Injecting HAProxy as a sidecar for basic traffic routing and load balancing.
   - **Observability:** Introduction of basic L4/L7 traffic metrics (request rates, error rates).
3. **Phase 3: Caddy 2**
   - **Architecture:** Swapping to Caddy 2 as a modern web server/proxy sidecar.
   - **Observability:** Enhanced metrics and easier configuration.
4. **Phase 4: Envoy (Cloud-Native)**
   - **Architecture:** Injecting Envoy, the industry standard cloud-native proxy.
   - **Observability:** Full distributed tracing (Tempo), rich L7 metrics, and deep network observability via the OpenTelemetry Collector.

## Infrastructure

- **Environment:** Ubuntu Multipass VM (4 vCPU, 12GB RAM)
- **Kubernetes:** K3s (Lightweight Kubernetes)
- **Observability Stack:**
  - Prometheus (Metrics)
  - Grafana (Dashboards)
  - Tempo (Distributed Tracing)
  - OpenTelemetry (OTEL) Collector (Telemetry Pipeline)

## Setup Instructions

1. **Bootstrap the Cluster:**
   ```bash
   ./setup-multipass-k3s.sh
   export KUBECONFIG=$(pwd)/kubeconfig.yaml
   ```
2. **Deploy the Observability Stack:**
   ```bash
   ./deploy-observability.sh
   ```
3. **Deploy the Baseline Application:**
   ```bash
   kubectl create namespace sock-shop
   kubectl apply -f manifests/base/sock-shop.yaml -n sock-shop
   ```
4. **Run Load Test:**
   ```bash
   kubectl apply -f manifests/base/load-generator.yaml
   ```

## Teardown
To completely remove the cluster and clean up resources:
```bash
./setup-multipass-k3s.sh --uninstall
```
