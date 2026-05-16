#!/bin/bash
set -e

INSTANCE_NAME="k3s-cluster"
CPUS="4"
MEM="12G"
DISK="30G"

export PATH=$PATH:/snap/bin

if [ "$1" == "--uninstall" ]; then
    echo ">>> Tearing down Multipass instance..."
    multipass delete $INSTANCE_NAME || true
    multipass purge
    rm -f kubeconfig.yaml
    echo ">>> Teardown complete."
    exit 0
fi

echo ">>> Launching Multipass VM ($INSTANCE_NAME)..."
if multipass info $INSTANCE_NAME >/dev/null 2>&1; then
    echo "Instance $INSTANCE_NAME already exists. Skipping creation."
else
    # Snap confinement blocks reading hidden files (starting with '.') even in $HOME!
    # Copying to a regular visible file in $HOME to bypass AppArmor block.
    cp cloud-init.yaml $HOME/k3s-cloud-init.yaml
    multipass launch --name $INSTANCE_NAME --cpus $CPUS --memory $MEM --disk $DISK --cloud-init $HOME/k3s-cloud-init.yaml
    rm -f $HOME/k3s-cloud-init.yaml
fi

echo ">>> Waiting for K3s to be ready..."
# Loop checking k3s status
multipass exec $INSTANCE_NAME -- bash -c 'until sudo k3s kubectl get nodes >/dev/null 2>&1; do echo "Waiting for k3s API..."; sleep 5; done'

echo ">>> Extracting kubeconfig..."
multipass exec $INSTANCE_NAME -- sudo cat /etc/rancher/k3s/k3s.yaml > kubeconfig.yaml
IP=$(multipass info $INSTANCE_NAME | grep IPv4 | awk '{print $2}')
sed -i "s/127.0.0.1/$IP/" kubeconfig.yaml
chmod 600 kubeconfig.yaml

echo ">>> K3s Cluster Nodes:"
export KUBECONFIG=$(pwd)/kubeconfig.yaml
kubectl get nodes

echo ">>> Setup complete! Use: export KUBECONFIG=\$(pwd)/kubeconfig.yaml"
