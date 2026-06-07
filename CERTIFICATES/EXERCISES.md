# 🧪 Esercizi Pratici — Certificati TLS/SSL

> **Pre-requisiti:** `openssl` installato (`openssl version` per verificare).  
> Su Linux/macOS è già presente. Su Windows usa WSL o Git Bash.

---

## Esercizio 1 — Creare una Root CA (Self-Signed)

**Obiettivo:** Creare la propria Certificate Authority locale, come si farebbe in un ambiente enterprise interno.

```bash
# 1. Crea la directory di lavoro
mkdir -p ~/pki-lab/{ca,server,client}
cd ~/pki-lab

# 2. Genera la chiave privata della Root CA
openssl genrsa -out ca/ca.key 4096

# 3. Genera il certificato self-signed della Root CA
openssl req -x509 -new -nodes \
  -key ca/ca.key \
  -sha256 -days 1825 \
  -out ca/ca.crt \
  -subj "/CN=MyLab-RootCA/O=CONSIP Lab/C=IT"

# 4. Verifica il risultato
openssl x509 -in ca/ca.crt -text -noout | grep -E "Subject:|Issuer:|Not|CA:"
```

**✅ Risultato atteso:** `Subject` e `Issuer` sono identici (self-signed). `CA:TRUE` nelle Basic Constraints.

**❓ Domanda:** Perché la Root CA deve avere `CA:TRUE` e i certificati server `CA:FALSE`?

<details>
<summary>💡 Risposta</summary>

`CA:TRUE` indica che il certificato può essere usato per firmare altri certificati. Se un certificato server avesse `CA:TRUE`, un attaccante che lo compromettesse potrebbe emettere certificati falsi fidati. Per questo i browser e i sistemi verificano che i certificati nella chain abbiano `CA:TRUE` e i leaf certificate abbiano `CA:FALSE`.
</details>

---

## Esercizio 2 — Emettere un Certificato Server

**Obiettivo:** Simulare il processo reale in cui un server richiede un certificato TLS firmato dalla CA.

```bash
cd ~/pki-lab

# 1. Genera la chiave privata del server
openssl genrsa -out server/server.key 2048

# 2. Crea la CSR (Certificate Signing Request)
openssl req -new \
  -key server/server.key \
  -out server/server.csr \
  -subj "/CN=myapp.lab.local/O=CONSIP Lab/C=IT"

# 3. Ispeziona la CSR — cosa contiene?
openssl req -in server/server.csr -text -noout

# 4. Crea il file con le estensioni SAN
cat > server/san.ext << 'EOF'
[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = myapp.lab.local
DNS.2 = localhost
IP.1  = 127.0.0.1
EOF

# 5. Firma la CSR con la CA
openssl x509 -req \
  -in server/server.csr \
  -CA ca/ca.crt \
  -CAkey ca/ca.key \
  -CAcreateserial \
  -out server/server.crt \
  -days 365 -sha256 \
  -extfile server/san.ext \
  -extensions req_ext

# 6. Verifica i SAN nel certificato emesso
openssl x509 -in server/server.crt -text -noout | grep -A5 "Subject Alternative"
```

**✅ Risultato atteso:** Il certificato mostra i SAN con `myapp.lab.local`, `localhost` e `127.0.0.1`.

**❓ Domanda:** Cosa succederebbe se tentassimo di usare questo certificato per un dominio non presente nei SAN?

<details>
<summary>💡 Risposta</summary>

Il client riceverebbe un errore `SSL_ERROR_BAD_CERT_DOMAIN` (Firefox) o `ERR_CERT_COMMON_NAME_INVALID` (Chrome). La validazione del dominio controlla i SAN, non il CN. Se il hostname richiesto non è in alcun SAN, la connessione viene rifiutata anche se il certificato è firmato da una CA fidata.
</details>

---

## Esercizio 3 — Verificare la Chain of Trust

**Obiettivo:** Capire come viene verificata la catena di fiducia e cosa succede se viene manomessa.

```bash
cd ~/pki-lab

# 1. Verifica il server.crt contro la CA
openssl verify -CAfile ca/ca.crt server/server.crt
# ✅ Risultato atteso: server/server.crt: OK

# 2. Cosa succede senza la CA?
openssl verify server/server.crt
# ❌ Risultato atteso: unable to get local issuer certificate

# 3. Simula manomissione — modifica un byte nel certificato
cp server/server.crt server/server-tampered.crt
printf '\x00' | dd of=server/server-tampered.crt bs=1 seek=100 conv=notrunc 2>/dev/null
openssl verify -CAfile ca/ca.crt server/server-tampered.crt
# ❌ Risultato atteso: signature failure

# 4. Controlla date di validità
openssl x509 -in server/server.crt -dates -noout

# 5. Controlla il fingerprint (hash univoco del certificato)
openssl x509 -in server/server.crt -fingerprint -sha256 -noout
openssl x509 -in ca/ca.crt -fingerprint -sha256 -noout
```

**✅ Risultato atteso:** Solo il `server.crt` originale supera la verifica. Il certificato manomesso fallisce la verifica della firma.

---

## Esercizio 4 — Simulare mTLS

**Obiettivo:** Creare certificati client e server, avviare un server TLS con `openssl s_server` e connettersi con autenticazione mutua.

```bash
cd ~/pki-lab

# --- Preparazione certificato CLIENT ---

# 1. Genera chiave e CSR del client
openssl genrsa -out client/client.key 2048
openssl req -new \
  -key client/client.key \
  -out client/client.csr \
  -subj "/CN=my-client-app/O=CONSIP Lab/C=IT"

# 2. Firma il certificato client con la stessa CA
openssl x509 -req \
  -in client/client.csr \
  -CA ca/ca.crt \
  -CAkey ca/ca.key \
  -CAcreateserial \
  -out client/client.crt \
  -days 365 -sha256

# --- Test mTLS ---

# TERMINALE 1: Avvia il server TLS (richiede certificato client con -Verify)
openssl s_server \
  -cert server/server.crt \
  -key server/server.key \
  -CAfile ca/ca.crt \
  -Verify 1 \
  -port 4433

# TERMINALE 2: Connettiti CON certificato client → deve funzionare
openssl s_client \
  -connect localhost:4433 \
  -cert client/client.crt \
  -key client/client.key \
  -CAfile ca/ca.crt

# TERMINALE 2: Connettiti SENZA certificato client → deve fallire
openssl s_client \
  -connect localhost:4433 \
  -CAfile ca/ca.crt
# ❌ Risultato atteso: handshake failure / alert
```

**✅ Risultato atteso:** Con certificato client → connessione stabilita. Senza → handshake failure.

**❓ Domanda:** In Kubernetes, quali componenti usano mTLS e quale CA firma i loro certificati?

<details>
<summary>💡 Risposta</summary>

In Kubernetes:
- **API Server ↔ kubelet**: mTLS, firmati da `kubernetes-ca`
- **API Server ↔ etcd**: mTLS, firmati da `etcd-ca` (CA separata)
- **API Server ↔ front-proxy**: firmati da `front-proxy-ca`
- **Service Mesh (Istio/Linkerd)**: mTLS automatico tra pod

I certificati Kubernetes si trovano in `/etc/kubernetes/pki/` sul control plane node.
</details>

---

## Esercizio 5 — Ispezionare Certificati Reali

**Obiettivo:** Usare `openssl s_client` per analizzare certificati di siti reali in produzione.

```bash
# 1. Ispeziona il certificato di github.com
echo | openssl s_client -connect github.com:443 -servername github.com 2>/dev/null \
  | openssl x509 -text -noout | grep -E "Subject:|Issuer:|DNS:|Not After"

# 2. Mostra tutta la chain di certificati
echo | openssl s_client -connect github.com:443 -showcerts 2>/dev/null

# 3. Verifica la versione TLS negoziata
echo | openssl s_client -connect github.com:443 2>/dev/null | grep "Protocol"

# 4. Forza TLS 1.2 esplicitamente
echo | openssl s_client -connect github.com:443 -tls1_2 2>/dev/null | grep "Protocol"

# 5. Controlla la scadenza del certificato
echo | openssl s_client -connect google.com:443 -servername google.com 2>/dev/null \
  | openssl x509 -noout -dates

# 6. Verifica il risultato della chain (depth)
echo | openssl s_client -connect github.com:443 2>/dev/null | grep -E "depth|verify"
```

**❓ Domanda:** Quanti livelli di chain ha il certificato di GitHub? Chi è la Root CA?

---

## Esercizio 6 — Formati e Conversioni (BONUS)

**Obiettivo:** Capire i diversi formati dei certificati e come convertirli (utile con Java/WebLogic).

```bash
cd ~/pki-lab

# 1. PEM → DER
openssl x509 -in server/server.crt -outform DER -out server/server.der
file server/server.der  # Binary data
file server/server.crt  # ASCII text (PEM)

# 2. Visualizza DER
openssl x509 -in server/server.der -inform DER -text -noout | head -20

# 3. Crea bundle PKCS12 (usato da Java, .NET, WebLogic, browser)
openssl pkcs12 -export \
  -out server/bundle.p12 \
  -inkey server/server.key \
  -in server/server.crt \
  -certfile ca/ca.crt \
  -passout pass:changeme

# 4. Estrai dal PKCS12
openssl pkcs12 -in server/bundle.p12 -out server/extracted.pem \
  -nodes -passin pass:changeme

# 5. Verifica corrispondenza chiave ↔ certificato
echo "=== Modulo del certificato ==="
openssl x509 -noout -modulus -in server/server.crt | md5sum
echo "=== Modulo della chiave ==="
openssl rsa  -noout -modulus -in server/server.key | md5sum
# ✅ I due hash devono essere IDENTICI
```

---

## 📋 Cheatsheet Finale

```bash
# Genera chiave RSA
openssl genrsa -out key.pem 2048

# Crea CSR
openssl req -new -key key.pem -out req.csr -subj "/CN=name/O=org/C=IT"

# Self-signed
openssl req -x509 -key key.pem -in req.csr -out cert.pem -days 365

# Firma con CA
openssl x509 -req -in req.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out cert.pem -days 365 -sha256

# Verifica
openssl verify -CAfile ca.crt cert.pem
openssl x509 -in cert.pem -text -noout

# Test connessione TLS
openssl s_client -connect host:443 -servername host

# Controlla scadenza
openssl x509 -in cert.pem -enddate -noout

# Match chiave ↔ certificato
openssl x509 -noout -modulus -in cert.pem | md5sum
openssl rsa  -noout -modulus -in key.pem  | md5sum
```
