# Observability Sidecar Demo: Weaveworks + LXD K3s

This project sets up a throwaway K3s environment using **LXC/LXD** to demonstrate how to instrument legacy microservices (Weaveworks Sock Shop) with modern observability using sidecar proxies (HAProxy and Envoy) without changing the application code.

## Phase 1: Infrastructure Setup
Run the bash script on your LXD-enabled hardware to spin up the K3s container. It automatically handles the necessary container privileges (`security.nesting`, `security.privileged`) required to run Docker/K3s inside LXC.

```bash
chmod +x setup-lxd-k3s.sh
./setup-lxd-k3s.sh
```

Once the script finishes, it will drop a `kubeconfig.yaml` in this directory. Export it to your local shell:
```bash
export KUBECONFIG=$PWD/kubeconfig.yaml
kubectl get nodes
```

## Next Phases
- **Phase 2:** Deploy Weaveworks Sock Shop legacy manifests.
- **Phase 3:** Inject HAProxy Sidecar for basic metrics/logging.
- **Phase 4:** Migrate to Envoy Sidecar for advanced OpenTelemetry tracing.

## Cleanup
When you are done testing, tear down the throwaway infrastructure:
```bash
lxc delete k3s-demo --force
rm kubeconfig.yaml
```
