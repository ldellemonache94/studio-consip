#!/usr/bin/env bash
set -euo pipefail

WORKDIR=$(mktemp -d)
cd "$WORKDIR"
echo "Workdir: $WORKDIR"

CSR_NAME="lab08-myapp-csr"

# 1. Chiave privata
openssl genrsa -out myapp.key 2048

# 2. CSR
openssl req -new -key myapp.key \
  -subj "/CN=myapp/O=labteam" \
  -out myapp.csr

# 3. Base64 senza newline
CSR_B64=$(base64 < myapp.csr | tr -d '\n')

# 4. Crea risorsa CertificateSigningRequest
kubectl delete csr "$CSR_NAME" --ignore-not-found=true

cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${CSR_NAME}
spec:
  request: ${CSR_B64}
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400
  usages:
    - client auth
EOF

# 5. Approva
kubectl certificate approve "$CSR_NAME"

# 6. Attendi firma e scarica
for i in $(seq 1 10); do
  CERT=$(kubectl get csr "$CSR_NAME" -o jsonpath='{.status.certificate}' 2>/dev/null || echo '')
  [ -n "$CERT" ] && break
  echo "Attendo firma... ($i/10)"
  sleep 2
done

kubectl get csr "$CSR_NAME" -o jsonpath='{.status.certificate}' | base64 -d > myapp.crt

# 7. Verifica
echo '--- Certificato ottenuto ---'
openssl x509 -in myapp.crt -text -noout | grep -E 'Subject:|Not Before:|Not After:'

echo "\nFile in: $WORKDIR"
