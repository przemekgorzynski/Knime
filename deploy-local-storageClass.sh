#!/bin/bash

set -euo pipefail

echo "Applying local-path-provisioner manifest..."

kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.31/deploy/local-path-storage.yaml

echo "✅ local-path-provisioner installed."
echo "➡️  Verifying installation..."

kubectl -n local-path-storage rollout status deploy/local-path-provisioner

echo "🔍 Current storage classes:"
kubectl get storageclass

kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
