#!/bin/bash
set -euo pipefail

# 🔍 1️⃣ Check for StorageClass
echo "🔍 Checking for existing StorageClass..."
if ! kubectl get storageclass >/dev/null 2>&1; then
  echo "⚠️  No StorageClass found. Deploying default local storageClass..."
  ./storageClass/deploy-local-storageClass.sh
else
  echo "✅ StorageClass already present."
fi

# 🔍 2️⃣ Check for External Secrets Operator (ESO)
echo "🔍 Checking for External Secrets Operator deployment..."
if ! kubectl get deploy external-secrets -n external-secrets >/dev/null 2>&1; then
  echo "⚠️  External Secrets Operator not found. Deploying default Bitwarden-backed configuration..."
  ./external-secrets-operator/deploy-externalSecret-operator.sh --provider bitwarden
else
  echo "✅ External Secrets Operator already deployed."
fi

# 🚀 3️⃣ Helm repo and dependencies
echo "📦 Adding Prometheus Helm repo (if not already added)..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update

echo "📁 Changing to 'monitoringStack' directory..."
cd monitoringStack

echo "🔧 Building Helm chart dependencies..."
helm dependency build

# 🚀 4️⃣ Deploy monitoring stack
echo "🚀 Installing or upgrading Prometheus Stack..."
helm upgrade --install prometheus-stack . \
  -n monitoring --create-namespace \
  -f values.yml

echo "✅ Prometheus Stack deployment triggered."

# 🛡 5️⃣ Verify StatefulSets rollout
echo "➡️ Waiting for Prometheus StatefulSet to be ready..."
kubectl -n monitoring rollout status sts/prometheus-prometheus-stack-kube-prom-prometheus --timeout=3m || \
  echo "⚠️  Prometheus StatefulSet rollout did not complete within 3 minutes."

echo "➡️ Waiting for Alertmanager StatefulSet to be ready..."
kubectl -n monitoring rollout status sts/alertmanager-prometheus-stack-kube-prom-alertmanager --timeout=3m || \
  echo "⚠️  Alertmanager StatefulSet rollout did not complete within 3 minutes."

# ✅ 6️⃣ Final status
echo "🔍 Current Helm releases in 'monitoring' namespace:"
helm list -n monitoring
