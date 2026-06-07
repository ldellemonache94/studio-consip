#!/usr/bin/env bash
set -euo pipefail

FAIL=0
WORKDIR="/tmp/lab10-debug"

check() {
  local desc=$1; shift
  if "$@" &>/dev/null; then
    echo "[OK]  $desc"
  else
    echo "[FAIL] $desc"
    FAIL=1
  fi
}

check "scenario A setup" test -f "$WORKDIR/A/server.crt"
check "scenario B setup" test -f "$WORKDIR/B/server.crt"
check "scenario C setup" test -f "$WORKDIR/C/server.crt"
check "scenario D setup" test -f "$WORKDIR/D/server.crt"
check "scenario E setup" test -f "$WORKDIR/E/active.crt"

check "B: SAN assente" \
  bash -c '! openssl x509 -in '$WORKDIR'/B/server.crt -ext subjectAltName -noout 2>&1 | grep -qi dns'

check "C: chain fallisce senza intermediate" \
  bash -c '! openssl verify -CAfile '$WORKDIR'/C/ca.crt '$WORKDIR'/C/server.crt'

check "C: chain passa con intermediate" \
  bash -c 'openssl verify -CAfile '$WORKDIR'/C/ca.crt -untrusted '$WORKDIR'/C/int.crt '$WORKDIR'/C/server.crt'

check "D: verify fallisce con CA sbagliata" \
  bash -c '! openssl verify -CAfile '$WORKDIR'/D/ca.crt '$WORKDIR'/D/server.crt'

check "D: verify passa con CA corretta" \
  bash -c 'openssl verify -CAfile '$WORKDIR'/D/other-ca.crt '$WORKDIR'/D/server.crt'

check "E: mismatch chiave/cert" \
  bash -c '[ "$(openssl x509 -in '$WORKDIR'/E/active.crt -noout -modulus | md5sum)" != "$(openssl rsa -in '$WORKDIR'/E/active.key -noout -modulus | md5sum)" ]'

if [ $FAIL -eq 0 ]; then
  echo "\n✅ Lab 10 setup verificato. Lavora con: bash solution.sh debug <A|B|C|D|E>"
else
  echo "\n❌ Setup incompleto. Esegui prima: bash solution.sh setup"
  exit 1
fi
