#!/usr/bin/env bash
set -euo pipefail

FAIL=0
PASS=changeit

check() {
  local desc=$1; shift
  if "$@" &>/dev/null; then
    echo "[OK]  $desc"
  else
    echo "[FAIL] $desc"
    FAIL=1
  fi
}

check "myapp.p12 esiste" test -f myapp.p12
check "truststore.p12 esiste" test -f truststore.p12
check "myapp-signed.crt esiste" test -f myapp-signed.crt
check "keystore contiene alias myapp" bash -c "keytool -list -keystore myapp.p12 -storetype PKCS12 -storepass $PASS | grep -q myapp"
check "truststore contiene alias local-ca" bash -c "keytool -list -keystore truststore.p12 -storetype PKCS12 -storepass $PASS | grep -q local-ca"
check "cert firmato ha SAN" bash -c 'openssl x509 -in myapp-signed.crt -ext subjectAltName -noout 2>&1 | grep -qi dns'

if [ $FAIL -eq 0 ]; then
  echo "\n✅ Lab 06 completato correttamente!"
else
  echo "\n❌ Alcuni controlli falliti. Rileggi solution.sh."
  exit 1
fi
