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
   kubectl apply -k manifests/base
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

### Phase 1 Findings (Baseline)
Running the baseline application, we can easily query infrastructure metrics (like `sum(rate(container_cpu_usage_seconds_total{namespace="sock-shop"}[1m])) by (pod)`) via Prometheus. However, we have **zero visibility** into the application layer. We cannot see HTTP request rates, 5xx error rates, latency histograms, or distributed traces. We are flying blind at L7.

### Phase 2 Findings (HAProxy)
By patching the `front-end` service to include an HAProxy sidecar and intercepting all traffic to port `8080`, we immediately unlocked L7 metrics (`haproxy_frontend_http_requests_total`). Using the Prometheus `sum(rate(...[1m])) by (proxy)` query, we could visualize a clear per-second HTTP request rate, giving us critical visibility without modifying the application source code.

### Phase 3 Findings (Caddy 2)
By swapping HAProxy for Caddy, we simplified our configuration down to a 6-line `Caddyfile`. Traffic was successfully tracked during our load test, yielding Prometheus metrics like `caddy_http_request_duration_seconds_count`. Caddy proved to be an excellent, lightweight option for basic HTTP telemetry.

### Phase 4 Findings (Envoy and Tempo)
The ultimate goal was distributed tracing. We injected Envoy into the `front-end` pods to natively intercept traffic. Envoy routed `ingress_http` listener stats to Prometheus and pushed gRPC traces to the OTEL Collector, which forwarded them to Tempo. This gave us the exact `traceID` and duration for every request traversing the cluster, providing total visibility to pinpoint latency bottlenecks—all with zero application code changes.
