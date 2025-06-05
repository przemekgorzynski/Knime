#!/bin/bash
set -euo pipefail

# 1️⃣ Required env vars check
if [[ -z "${BWS_ACCESS_TOKEN:-}" || -z "${BWS_ORGANIZATION_ID:-}" || -z "${BWS_PROJECT_ID:-}" ]]; then
  echo "❌ Missing one of: BWS_ACCESS_TOKEN, BWS_ORGANIZATION_ID, BWS_PROJECT_ID"
  exit 1
fi

# 2️⃣ Generate TLS certificates with SAN (Subject Alternative Name)
echo "🔐 Generating TLS certificates with SAN..."
mkdir -p tls

openssl genrsa -out tls/ca.key 4096
openssl req -x509 -new -nodes -key tls/ca.key -sha256 -days 365 \
  -subj "/CN=bitwarden-sdk-ca" -out tls/ca.crt

openssl genrsa -out tls/tls.key 2048
openssl req -new -key tls/tls.key \
  -subj "/CN=bitwarden-sdk-server.external-secrets.svc.cluster.local" \
  -addext "subjectAltName = DNS:bitwarden-sdk-server.external-secrets.svc.cluster.local" \
  -out tls/tls.csr

openssl x509 -req -in tls/tls.csr -CA tls/ca.crt -CAkey tls/ca.key \
  -CAcreateserial -out tls/tls.crt -days 365 -sha256 \
  -extfile <(printf "subjectAltName=DNS:bitwarden-sdk-server.external-secrets.svc.cluster.local")

# 3️⃣ Create Kubernetes TLS secret
echo "🔐 Creating Kubernetes TLS secret 'bitwarden-tls-certs' with proper key names..."
kubectl create namespace external-secrets || true
kubectl create secret generic bitwarden-tls-certs \
  -n external-secrets \
  --dry-run=client -o yaml \
  --from-file=tls.crt=tls/tls.crt \
  --from-file=tls.key=tls/tls.key \
  --from-file=ca.crt=tls/ca.crt | kubectl apply -f -

# 4️⃣ Encode CA for ClusterSecretStore
CA_BUNDLE=$(base64 < tls/ca.crt | tr -d '\n')

# 5️⃣ Install External-Secrets Operator with Bitwarden SDK server
echo "🚀 Installing External-Secrets Operator..."
helm upgrade --install external-secrets external-secrets/external-secrets \
  -n external-secrets --create-namespace \
  --set bitwarden-sdk-server.enabled=true \
  --set bitwarden-sdk-server.tls.enabled=true \
  --set bitwarden-sdk-server.tls.secretName=bitwarden-tls-certs

# 6️⃣ Wait for webhook to be ready
echo "⏳ Waiting for webhook to be ready..."
kubectl -n external-secrets rollout status \
  deploy/external-secrets-webhook --timeout=2m

# 7️⃣ Create Bitwarden access-token secret
echo "🔐 Creating Bitwarden access-token secret..."
kubectl create secret generic bitwarden-access-token \
  --from-literal=token="${BWS_ACCESS_TOKEN}" \
  -n external-secrets --dry-run=client -o yaml | kubectl apply -f -

# 8️⃣ Write and apply ClusterSecretStore manifest
echo "📄 Creating Bitwarden ClusterSecretStore manifest..."
cat <<EOF > bitwarden-secret-store.yaml
apiVersion: external-secrets.io/v1
kind: ClusterSecretStore
metadata:
  name: bitwarden-secretsmanager
spec:
  provider:
    bitwardensecretsmanager:
      apiURL: https://api.bitwarden.com
      identityURL: https://identity.bitwarden.com
      auth:
        secretRef:
          credentials:
            name: bitwarden-access-token
            namespace: external-secrets
            key: token
      bitwardenServerSDKURL: https://bitwarden-sdk-server.external-secrets.svc.cluster.local:9998
      caBundle: ${CA_BUNDLE}
      organizationID: ${BWS_ORGANIZATION_ID}
      projectID: ${BWS_PROJECT_ID}
EOF

echo "📤 Applying ClusterSecretStore..."
kubectl apply -f bitwarden-secret-store.yaml

# 9️⃣ Cleanup local TLS files
echo "🧹 Cleaning up local TLS files..."
rm -rf tls bitwarden-secret-store.yaml

echo "✅ Bitwarden ClusterSecretStore configured successfully!"
