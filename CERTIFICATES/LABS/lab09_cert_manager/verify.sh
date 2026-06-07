#!/usr/bin/env bash
set -euo pipefail

FAIL=0
NS=default

check() {
  local desc=$1; shift
  if "$@" &>/dev/null; then
    echo "[OK]  $desc"
  else
    echo "[FAIL] $desc"
    FAIL=1
  fi
}

check "ClusterIssuer internal-ca-issuer pronto" \
  bash -c 'kubectl get clusterissuer internal-ca-issuer -o jsonpath="{.status.conditions[0].type}" | grep -q Ready'
check "Certificate myapp-cert pronto" \
  bash -c "kubectl get certificate myapp-cert -n $NS -o jsonpath='{.status.conditions[0].type}' | grep -q Ready"
check "Secret myapp-tls esiste" \
  kubectl get secret myapp-tls -n $NS
check "tls.crt e' un certificato valido" \
  bash -c "kubectl get secret myapp-tls -n $NS -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout"
check "SAN presenti" \
  bash -c "kubectl get secret myapp-tls -n $NS -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -ext subjectAltName -noout 2>&1 | grep -qi dns"

if [ $FAIL -eq 0 ]; then
  echo "\n✅ Lab 09 completato correttamente!"
else
  echo "\n❌ Alcuni controlli falliti. Rileggi solution.sh."
  exit 1
fi
