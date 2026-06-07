#!/usr/bin/env bash
set -euo pipefail

FAIL=0
CSR_NAME="lab08-myapp-csr"

check() {
  local desc=$1; shift
  if "$@" &>/dev/null; then
    echo "[OK]  $desc"
  else
    echo "[FAIL] $desc"
    FAIL=1
  fi
}

check "myapp.crt esiste" test -f myapp.crt
check "myapp.crt e' un certificato valido" openssl x509 -in myapp.crt -noout
check "CSR approvata in cluster" \
  bash -c "kubectl get csr $CSR_NAME -o jsonpath='{.status.conditions[0].type}' | grep -q Approved"
check "CN e' myapp" \
  bash -c 'openssl x509 -in myapp.crt -subject -noout | grep -q CN=myapp'

if [ $FAIL -eq 0 ]; then
  echo "\n✅ Lab 08 completato correttamente!"
else
  echo "\n❌ Alcuni controlli falliti. Rileggi solution.sh."
  exit 1
fi
