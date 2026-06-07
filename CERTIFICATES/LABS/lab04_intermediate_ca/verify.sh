#!/usr/bin/env bash
set -euo pipefail

FAIL=0

check() {
  local desc=$1; shift
  if "$@" &>/dev/null; then
    echo "[OK]  $desc"
  else
    echo "[FAIL] $desc"
    FAIL=1
  fi
}

check "root-ca.crt esiste" test -f root-ca.crt
check "intermediate-ca.crt esiste" test -f intermediate-ca.crt
check "server.crt esiste" test -f server.crt
check "chain.pem esiste" test -f chain.pem

check "root-ca è una CA" bash -c 'openssl x509 -in root-ca.crt -text -noout | grep -q "CA:TRUE"'
check "intermediate è una CA" bash -c 'openssl x509 -in intermediate-ca.crt -text -noout | grep -q "CA:TRUE"'
check "server cert NON è CA" bash -c '! openssl x509 -in server.crt -text -noout | grep -q "CA:TRUE"'
check "chain valida" openssl verify -CAfile root-ca.crt -untrusted intermediate-ca.crt server.crt
check "server ha SAN" bash -c 'openssl x509 -in server.crt -ext subjectAltName -noout 2>&1 | grep -qi dns'

if [ $FAIL -eq 0 ]; then
  echo "\n✅ Lab 04 completato correttamente!"
else
  echo "\n❌ Alcuni controlli falliti. Rileggi solution.sh."
  exit 1
fi
