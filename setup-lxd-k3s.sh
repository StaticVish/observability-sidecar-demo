#!/bin/bash
set -e

CONTAINER_NAME="k3s-demo"

echo ">>> Launching LXD container ($CONTAINER_NAME)..."
# Using nesting, privileged, and unconfined apparmor for smooth K3s execution in LXC
lxc launch images:ubuntu/22.04 $CONTAINER_NAME \
  -c security.nesting=true \
  -c security.privileged=true \
  -c raw.lxc="lxc.apparmor.profile=unconfined"

echo ">>> Waiting for container to get an IPv4 address..."
sleep 5
while [ -z "$(lxc list $CONTAINER_NAME -c 4 --format csv | awk '{print $1}')" ]; do
    sleep 2
done

IP_ADDR=$(lxc list $CONTAINER_NAME -c 4 --format csv | awk '{print $1}')
echo ">>> Container IP: $IP_ADDR"

echo ">>> Installing K3s inside the container..."
lxc exec $CONTAINER_NAME -- sh -c "curl -sfL https://get.k3s.io | sh -"

echo ">>> Waiting for K3s to be ready..."
sleep 15
lxc exec $CONTAINER_NAME -- sh -c "k3s kubectl wait --for=condition=Ready nodes --all --timeout=120s"

echo ">>> Extracting kubeconfig to local directory..."
lxc exec $CONTAINER_NAME -- cat /etc/rancher/k3s/k3s.yaml > kubeconfig.yaml

# Replace localhost with the container's routable IP
sed -i "s/127.0.0.1/$IP_ADDR/g" kubeconfig.yaml
chmod 600 kubeconfig.yaml

echo "======================================================"
echo ">>> Done! To connect to the throwaway cluster, run:"
echo "export KUBECONFIG=\$PWD/kubeconfig.yaml"
echo "kubectl get nodes"
echo "======================================================"
