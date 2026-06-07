#!/usr/bin/env bash
set -euo pipefail

WORKDIR=$(mktemp -d)
cd "$WORKDIR"
echo "Workdir: $WORKDIR"

PASS=changeit

# 1. CA locale con openssl
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 \
  -subj "/CN=LocalCA/O=Lab/C=IT" -out ca.crt

# 2. Keypair nel keystore PKCS12
keytool -genkeypair \
  -alias myapp \
  -keyalg RSA -keysize 2048 -validity 365 \
  -dname "CN=myapp.example.com, O=Lab, C=IT" \
  -keystore myapp.p12 -storetype PKCS12 \
  -storepass "$PASS" -keypass "$PASS"

# 3. CSR
keytool -certreq -alias myapp -file myapp.csr \
  -keystore myapp.p12 -storetype PKCS12 -storepass "$PASS"

# 4. Firma CSR con openssl (aggiunge SAN)
openssl x509 -req -in myapp.csr \
  -CA ca.crt -CAkey ca.key -CAcreateserial \
  -sha256 -days 365 \
  -extensions v3_ext \
  -extfile <(printf '[v3_ext]\nsubjectAltName=DNS:myapp.example.com\nextendedKeyUsage=serverAuth') \
  -out myapp-signed.crt

# 5. Truststore: importa CA
keytool -importcert -alias local-ca -file ca.crt \
  -keystore truststore.p12 -storetype PKCS12 \
  -storepass "$PASS" -noprompt

# 6. Keystore: importa CA prima del cert firmato
keytool -importcert -alias local-ca -file ca.crt \
  -keystore myapp.p12 -storetype PKCS12 \
  -storepass "$PASS" -noprompt

# 7. Keystore: importa cert firmato
keytool -importcert -alias myapp -file myapp-signed.crt \
  -keystore myapp.p12 -storetype PKCS12 \
  -storepass "$PASS" -noprompt

# 8. Verifica
echo '--- Keystore ---'
keytool -list -v -keystore myapp.p12 -storetype PKCS12 -storepass "$PASS"
echo '--- Truststore ---'
keytool -list -v -keystore truststore.p12 -storetype PKCS12 -storepass "$PASS"

echo "\nFile generati in: $WORKDIR"
