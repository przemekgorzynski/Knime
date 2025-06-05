#!/bin/bash

set -euo pipefail

echo "📦 Adding CSI Driver NFS Helm repository..."
helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts

echo "🔄 Updating Helm repositories..."
helm repo update

echo "📁 Changing to 'nfs-storageClass' directory..."
cd nfs-storageClass

echo "🔧 Building Helm chart dependencies..."
helm dependency build

echo "🚀 Installing or upgrading NFS CSI driver..."
helm upgrade --install nfs-csi . \
  -n kube-system --create-namespace \
  -f values.yml

echo "✅ NFS CSI driver deployed successfully."
echo "➡️  Verifying rollout status..."

kubectl -n kube-system rollout status daemonset/nfs-csi-node || true
kubectl -n kube-system rollout status deployment/nfs-csi-controller || true

echo "🔍 Current Helm releases in 'kube-system' namespace:"
helm list -n kube-system
