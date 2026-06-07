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

  # Scenario A: certificato scaduto
  mkdir -p A
  openssl genrsa -out A/server.key 2048 2>/dev/null
  openssl req -new -key A/server.key -subj "/CN=expired.example.com" -out A/server.csr 2>/dev/null
  # Firma con date nel passato
  faketime -f '-400d' openssl x509 -req -in A/server.csr \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -days 1 -sha256 \
    -extfile <(echo 'subjectAltName=DNS:expired.example.com') \
    -out A/server.crt 2>/dev/null || \
  openssl x509 -req -in A/server.csr \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -days 1 -sha256 \
    -extfile <(echo 'subjectAltName=DNS:expired.example.com') \
    -out A/server.crt 2>/dev/null
  cp ca.crt A/ca.crt

  # Scenario B: SAN mancante
  mkdir -p B
  openssl genrsa -out B/server.key 2048 2>/dev/null
  openssl req -new -key B/server.key -subj "/CN=noSAN.example.com" -out B/server.csr 2>/dev/null
  openssl x509 -req -in B/server.csr \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -days 365 -sha256 \
    -out B/server.crt 2>/dev/null  # nessun SAN
  cp ca.crt B/ca.crt

  # Scenario C: chain incompleta (intermediate non inviato)
  mkdir -p C
  openssl genrsa -out C/int.key 4096 2>/dev/null
  openssl req -new -key C/int.key -subj "/CN=IntCA/O=Lab" -out C/int.csr 2>/dev/null
  openssl x509 -req -in C/int.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
    -days 1825 -sha256 \
    -extfile <(echo 'basicConstraints=CA:TRUE,pathlen:0') \
    -out C/int.crt 2>/dev/null
  openssl genrsa -out C/server.key 2048 2>/dev/null
  openssl req -new -key C/server.key -subj "/CN=chain.example.com" -out C/server.csr 2>/dev/null
  openssl x509 -req -in C/server.csr -CA C/int.crt -CAkey C/int.key -CAcreateserial \
    -days 365 -sha256 \
    -extfile <(echo 'subjectAltName=DNS:chain.example.com') \
    -out C/server.crt 2>/dev/null
  # NON copiamo int.crt → scenario chain incompleta
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
    -extfile <(echo 'subjectAltName=DNS:other.example.com') \
    -out D/server.crt 2>/dev/null
  cp ca.crt D/ca.crt  # ca.crt NON firma server.crt → untrusted

  # Scenario E: chiave non corrisponde al certificato
  mkdir -p E
  openssl genrsa -out E/server.key 2048 2>/dev/null
  openssl genrsa -out E/wrong.key 2048 2>/dev/null  # chiave diversa
  openssl req -new -key E/server.key -subj "/CN=mismatch.example.com" -out E/server.csr 2>/dev/null
  openssl x509 -req -in E/server.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
    -days 365 -sha256 \
    -extfile <(echo 'subjectAltName=DNS:mismatch.example.com') \
    -out E/server.crt 2>/dev/null
  cp E/wrong.key E/active.key  # active.key è sbagliata
  cp E/server.crt E/active.crt
  cp ca.crt E/ca.crt

  echo "✅ Scenari generati in $WORKDIR"
  echo "Usa: bash solution.sh debug <A|B|C|D|E>"
}

debug_scenario() {
  cd "$WORKDIR"
  case $SCENARIO in
    A)
      echo "=== Scenario A: cert scaduto ==="
      echo "--- Date ---"
      openssl x509 -in A/server.crt -dates -noout
      echo "--- Verifica ---"
      openssl verify -CAfile A/ca.crt A/server.crt || true
      echo "\n[FIX] Rigenera il certificato con una data valida."
      ;;
    B)
      echo "=== Scenario B: SAN mancante ==="
      echo "--- SAN ---"
      openssl x509 -in B/server.crt -ext subjectAltName -noout 2>&1 || echo '(nessun SAN)'
      echo "--- Subject ---"
      openssl x509 -in B/server.crt -subject -noout
      echo "\n[FIX] Rigenera il cert includendo -extfile con subjectAltName."
      ;;
    C)
      echo "=== Scenario C: chain incompleta ==="
      echo "--- Verifica senza intermediate (fallisce) ---"
      openssl verify -CAfile C/ca.crt C/server.crt || true
      echo "\n[FIX] Passa l'intermediate: openssl verify -CAfile C/ca.crt -untrusted C/int.crt C/server.crt"
      ;;
    D)
      echo "=== Scenario D: CA non nel trust store ==="
      echo "--- Verifica con CA sbagliata (fallisce) ---"
      openssl verify -CAfile D/ca.crt D/server.crt || true
      echo "\n[FIX] Usa la CA corretta: openssl verify -CAfile D/other-ca.crt D/server.crt"
      ;;
    E)
      echo "=== Scenario E: chiave e cert non corrispondono ==="
      echo "--- Modulo certificato ---"
      openssl x509 -in E/active.crt -noout -modulus | md5sum
      echo "--- Modulo chiave attiva ---"
      openssl rsa -in E/active.key -noout -modulus | md5sum
      echo "--- Modulo chiave corretta ---"
      openssl rsa -in E/server.key -noout -modulus | md5sum
      echo "\n[FIX] Usa E/server.key con E/active.crt."
      ;;
    *)
      echo "Scenario non riconosciuto. Usa A, B, C, D o E."
      ;;
  esac
}

case $CMD in
  setup)  setup ;;
  debug)  debug_scenario ;;
  *)      echo "Uso: bash solution.sh <setup|debug> [A|B|C|D|E]" ;;
esac
