#!/bin/bash
set -e

export PATH=$PATH:/snap/bin

VM_NAME="k3s-cluster"

if [ "$1" == "--uninstall" ]; then
    echo ">>> Wiping everything for $VM_NAME..."
    lxc delete $VM_NAME --force 2>/dev/null || true
    rm -f kubeconfig.yaml
    echo ">>> Cleanup complete."
    exit 0
fi

echo ">>> Launching LXD VM ($VM_NAME)..."
lxc launch ubuntu:22.04 $VM_NAME --vm \
  -c limits.cpu=4 \
  -c limits.memory=12GB

echo ">>> Waiting for LXD agent to be ready inside the VM (this takes a moment)..."
while ! lxc exec $VM_NAME -- true 2>/dev/null; do
    sleep 2
done

echo ">>> Waiting for VM to acquire an IPv4 address..."
while [ -z "$(lxc list $VM_NAME -c 4 --format csv | awk '{print $1}')" ]; do
    sleep 2
done

IP_ADDR=$(lxc list $VM_NAME -c 4 --format csv | awk '{print $1}')
echo ">>> VM IP: $IP_ADDR"

echo ">>> Installing K3s inside the VM..."
lxc exec $VM_NAME -- sh -c "curl -sfL https://get.k3s.io | sh -"

echo ">>> Waiting for K3s to be ready..."
sleep 15
lxc exec $VM_NAME -- sh -c "k3s kubectl wait --for=condition=Ready nodes --all --timeout=120s"

echo ">>> Extracting kubeconfig to local directory..."
lxc exec $VM_NAME -- cat /etc/rancher/k3s/k3s.yaml > kubeconfig.yaml

# Replace localhost with the VM's routable IP
sed -i "s/127.0.0.1/$IP_ADDR/g" kubeconfig.yaml
chmod 600 kubeconfig.yaml

echo "======================================================"
echo ">>> Done! To connect to the throwaway cluster, run:"
echo "export KUBECONFIG=\$PWD/kubeconfig.yaml"
echo "kubectl get nodes"
echo "======================================================"
