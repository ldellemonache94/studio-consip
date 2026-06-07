#!/usr/bin/env bash
set -euo pipefail

WORKDIR=$(mktemp -d)
cd "$WORKDIR"
echo "Workdir: $WORKDIR"

# 1. Root CA
openssl genrsa -out root-ca.key 4096
openssl req -x509 -new -nodes \
  -key root-ca.key \
  -sha256 -days 3650 \
  -subj "/CN=Root CA/O=Lab/C=IT" \
  -extensions v3_ca \
  -config <(cat /etc/ssl/openssl.cnf; echo '[v3_ca]\nbasicConstraints=CA:TRUE,pathlen:1\nkeyUsage=keyCertSign,cRLSign') \
  -out root-ca.crt

# 2. Intermediate CA
openssl genrsa -out intermediate-ca.key 4096
openssl req -new \
  -key intermediate-ca.key \
  -subj "/CN=Intermediate CA/O=Lab/C=IT" \
  -out intermediate-ca.csr
openssl x509 -req \
  -in intermediate-ca.csr \
  -CA root-ca.crt -CAkey root-ca.key -CAcreateserial \
  -sha256 -days 1825 \
  -extensions v3_intermediate_ca \
  -extfile <(echo '[v3_intermediate_ca]\nbasicConstraints=CA:TRUE,pathlen:0\nkeyUsage=keyCertSign,cRLSign\nsubjectKeyIdentifier=hash\nauthorityKeyIdentifier=keyid') \
  -out intermediate-ca.crt

# 3. Server cert con SAN
openssl genrsa -out server.key 2048
openssl req -new \
  -key server.key \
  -subj "/CN=server.example.com" \
  -out server.csr
openssl x509 -req \
  -in server.csr \
  -CA intermediate-ca.crt -CAkey intermediate-ca.key -CAcreateserial \
  -sha256 -days 365 \
  -extensions v3_server \
  -extfile <(echo '[v3_server]\nbasicConstraints=CA:FALSE\nkeyUsage=digitalSignature,keyEncipherment\nextendedKeyUsage=serverAuth\nsubjectAltName=DNS:server.example.com,DNS:localhost') \
  -out server.crt

# 4. Chain file
cat server.crt intermediate-ca.crt > chain.pem

# 5. Verifica
echo '--- Verifica chain ---'
openssl verify -CAfile root-ca.crt -untrusted intermediate-ca.crt server.crt

echo "\nFile generati in: $WORKDIR"
ls -la
