#!/usr/bin/env bash
set -euo pipefail

NS=default

# 1. ClusterIssuer self-signed bootstrap
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-bootstrap
spec:
  selfSigned: {}
EOF

# 2. CA interna
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: internal-ca
  namespace: cert-manager
spec:
  isCA: true
  secretName: internal-ca-key-pair
  commonName: internal-ca
  issuerRef:
    name: selfsigned-bootstrap
    kind: ClusterIssuer
  duration: 87600h
  renewBefore: 720h
EOF

kubectl wait --for=condition=Ready certificate/internal-ca -n cert-manager --timeout=60s

# 3. ClusterIssuer che usa la CA interna
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: internal-ca-issuer
spec:
  ca:
    secretName: internal-ca-key-pair
EOF

# 4. Certificate per workload
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: myapp-cert
  namespace: $NS
spec:
  secretName: myapp-tls
  issuerRef:
    name: internal-ca-issuer
    kind: ClusterIssuer
  commonName: myapp.example.com
  dnsNames:
    - myapp.example.com
    - myapp.$NS.svc.cluster.local
  duration: 2160h
  renewBefore: 360h
EOF

kubectl wait --for=condition=Ready certificate/myapp-cert -n $NS --timeout=60s

# 5. Verifica
echo '--- Certificato emesso ---'
kubectl get secret myapp-tls -n $NS \
  -o jsonpath='{.data.tls\.crt}' | base64 -d | \
  openssl x509 -text -noout | grep -E 'Subject:|DNS:|Not After:'
