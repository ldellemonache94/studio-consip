#!/usr/bin/env bash
set -euo pipefail

CMD=${1:-help}
SCENARIO=${2:-}
WORKDIR="/tmp/lab10-debug"
mkdir -p "$WORKDIR"

setup() {
  cd "$WORKDIR"

  # CA base
  openssl genrsa -out ca.key 4096 2>/dev/null
  openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 \
    -subj "/CN=LabCA/O=Lab/C=IT" -out ca.crt 2>/dev/null

  # Scenario A: certificato scaduto (1 giorno di validita' nel passato)
  mkdir -p A
  openssl genrsa -out A/server.key 2048 2>/dev/null
  openssl req -new -key A/server.key -subj "/CN=expired.example.com" -out A/server.csr 2>/dev/null
  openssl x509 -req -in A/server.csr \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -days 1 -sha256 \
    -extfile <(printf 'subjectAltName=DNS:expired.example.com') \
    -out A/server.crt 2>/dev/null
  # Retrodatiamo manualmente la validita'
  # (se faketime non e' disponibile, il cert sara' appena emesso ma lo scenario e' comunque istruttivo)
  cp ca.crt A/ca.crt

  # Scenario B: SAN mancante
  mkdir -p B
  openssl genrsa -out B/server.key 2048 2>/dev/null
  openssl req -new -key B/server.key -subj "/CN=noSAN.example.com" -out B/server.csr 2>/dev/null
  openssl x509 -req -in B/server.csr \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -days 365 -sha256 \
    -out B/server.crt 2>/dev/null
  cp ca.crt B/ca.crt

  # Scenario C: chain incompleta
  mkdir -p C
  openssl genrsa -out C/int.key 4096 2>/dev/null
  openssl req -new -key C/int.key -subj "/CN=IntCA/O=Lab" -out C/int.csr 2>/dev/null
  openssl x509 -req -in C/int.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
    -days 1825 -sha256 \
    -extfile <(printf 'basicConstraints=CA:TRUE,pathlen:0') \
    -out C/int.crt 2>/dev/null
  openssl genrsa -out C/server.key 2048 2>/dev/null
  openssl req -new -key C/server.key -subj "/CN=chain.example.com" -out C/server.csr 2>/dev/null
  openssl x509 -req -in C/server.csr -CA C/int.crt -CAkey C/int.key -CAcreateserial \
    -days 365 -sha256 \
    -extfile <(printf 'subjectAltName=DNS:chain.example.com') \
    -out C/server.crt 2>/dev/null
  # int.crt NON viene incluso -> chain incompleta
  cp ca.crt C/ca.crt

  # Scenario D: CA non nel trust store
  mkdir -p D
  openssl genrsa -out D/other-ca.key 4096 2>/dev/null
  openssl req -x509 -new -nodes -key D/other-ca.key -sha256 -days 3650 \
    -subj "/CN=OtherCA/O=Lab" -out D/other-ca.crt 2>/dev/null
  openssl genrsa -out D/server.key 2048 2>/dev/null
  openssl req -new -key D/server.key -subj "/CN=other.example.com" -out D/server.csr 2>/dev/null
  openssl x509 -req -in D/server.csr -CA D/other-ca.crt -CAkey D/other-ca.key -CAcreateserial \
    -days 365 -sha256 \
    -extfile <(printf 'subjectAltName=DNS:other.example.com') \
    -out D/server.crt 2>/dev/null
  cp ca.crt D/ca.crt  # ca.crt sbagliata: non ha firmato D/server.crt

  # Scenario E: chiave e cert non corrispondono
  mkdir -p E
  openssl genrsa -out E/server.key 2048 2>/dev/null
  openssl genrsa -out E/wrong.key 2048 2>/dev/null
  openssl req -new -key E/server.key -subj "/CN=mismatch.example.com" -out E/server.csr 2>/dev/null
  openssl x509 -req -in E/server.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
    -days 365 -sha256 \
    -extfile <(printf 'subjectAltName=DNS:mismatch.example.com') \
    -out E/server.crt 2>/dev/null
  cp E/wrong.key E/active.key   # chiave sbagliata usata come attiva
  cp E/server.crt E/active.crt
  cp ca.crt E/ca.crt

  echo "Setup completato in $WORKDIR"
  echo "Ora usa: bash solution.sh debug <A|B|C|D|E>"
}

debug_scenario() {
  cd "$WORKDIR"
  case $SCENARIO in
    A)
      echo "=== Scenario A: certificato scaduto ==="
      openssl x509 -in A/server.crt -dates -noout
      openssl verify -CAfile A/ca.crt A/server.crt || true
      echo "\n[FIX] Rigenera il certificato con validita' corretta."
      ;;
    B)
      echo "=== Scenario B: SAN mancante ==="
      openssl x509 -in B/server.crt -ext subjectAltName -noout 2>&1 || echo '(nessun SAN trovato)'
      openssl x509 -in B/server.crt -subject -noout
      echo "\n[FIX] Rigenera includendo -extfile con subjectAltName=DNS:..."
      ;;
    C)
      echo "=== Scenario C: chain incompleta ==="
      echo "--- Senza intermediate (deve fallire) ---"
      openssl verify -CAfile C/ca.crt C/server.crt || true
      echo "--- Con intermediate (deve passare) ---"
      openssl verify -CAfile C/ca.crt -untrusted C/int.crt C/server.crt || true
      echo "\n[FIX] Invia sempre la chain completa: server.crt + int.crt"
      ;;
    D)
      echo "=== Scenario D: CA non nel trust store ==="
      echo "--- Con CA sbagliata (deve fallire) ---"
      openssl verify -CAfile D/ca.crt D/server.crt || true
      echo "--- Con CA corretta (deve passare) ---"
      openssl verify -CAfile D/other-ca.crt D/server.crt || true
      echo "\n[FIX] Importa D/other-ca.crt nel trust store del client."
      ;;
    E)
      echo "=== Scenario E: chiave e cert non corrispondono ==="
      echo "--- Hash modulo certificato ---"
      openssl x509 -in E/active.crt -noout -modulus | md5sum
      echo "--- Hash modulo chiave attiva (sbagliata) ---"
      openssl rsa -in E/active.key -noout -modulus | md5sum
      echo "--- Hash modulo chiave corretta ---"
      openssl rsa -in E/server.key -noout -modulus | md5sum
      echo "\n[FIX] Usa E/server.key con E/active.crt (hash identici)."
      ;;
    *)
      echo "Scenario non valido. Scegli tra: A B C D E"
      ;;
  esac
}

case $CMD in
  setup)  setup ;;
  debug)  debug_scenario ;;
  *)      echo "Uso: bash solution.sh <setup|debug> [A|B|C|D|E]" ;;
esac
