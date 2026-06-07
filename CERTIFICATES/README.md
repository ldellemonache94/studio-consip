# 🔐 Certificati TLS/SSL — Teoria Completa

> **Obiettivo:** Capire come funzionano i certificati X.509, la PKI, il TLS Handshake, i Self-Signed Certificates e la Mutual TLS (mTLS). Al termine sarai in grado di creare, firmare e verificare certificati con `openssl`.

---

## 📚 Indice

1. [Cos'è un Certificato X.509](#1-cosè-un-certificato-x509)
2. [PKI e Chain of Trust](#2-pki-e-chain-of-trust)
3. [TLS Handshake step-by-step](#3-tls-handshake-step-by-step)
4. [Self-Signed Certificates](#4-self-signed-certificates)
5. [Mutual TLS (mTLS)](#5-mutual-tls-mtls)
6. [Comandi OpenSSL essenziali](#6-comandi-openssl-essenziali)
7. [Esercizi pratici](./EXERCISES.md)
8. [Risorse di studio](./STUDY.md)

---

## 1. Cos'è un Certificato X.509

Un certificato X.509 è un documento digitale standardizzato (RFC 5280) che lega una **chiave pubblica** a un'**identità** (persona, server, organizzazione). È il fondamento di HTTPS, mTLS, firma di codice e molto altro.

### Struttura di un certificato X.509

```
┌─────────────────────────────────────────────┐
│              CERTIFICATO X.509              │
├─────────────────────────────────────────────┤
│  Version          : v3                      │
│  Serial Number    : 0x1A2B3C...             │
│  Signature Alg    : sha256WithRSAEncryption │
│  Issuer           : CN=My-CA, O=CONSIP      │
│  Validity         : 2025-01-01 / 2026-01-01 │
│  Subject          : CN=myserver.example.com │
│  Public Key       : RSA 2048-bit            │
├─────────────────────────────────────────────┤
│  Extensions (v3):                           │
│    Subject Alt Name (SAN): myserver.com     │
│    Key Usage: digitalSignature, keyEnc      │
│    Basic Constraints: CA:FALSE              │
├─────────────────────────────────────────────┤
│  Signature (firmata dalla CA)               │
└─────────────────────────────────────────────┘
```

### Campi fondamentali

| Campo | Descrizione |
|---|---|
| **Subject** | Chi possiede il certificato (CN, O, C...) |
| **Issuer** | Chi ha firmato il certificato (la CA) |
| **Validity** | Periodo di validità (notBefore / notAfter) |
| **Public Key** | La chiave pubblica del soggetto |
| **SAN** | Subject Alternative Names — domini alternativi |
| **Basic Constraints** | Se `CA:TRUE`, può firmare altri certificati |
| **Signature** | Firma digitale dell'Issuer (la CA) |

> ⚠️ **Nota importante:** I browser moderni richiedono il campo **SAN** (Subject Alternative Name). Il CN da solo non è più sufficiente per la validazione del dominio.

---

## 2. PKI e Chain of Trust

La **PKI (Public Key Infrastructure)** è il sistema che permette di fidarsi di un certificato. Il concetto chiave è la **Chain of Trust** (catena di fiducia).

### Gerarchia della PKI

```
        ┌──────────────────┐
        │   Root CA        │  ← Auto-firmata, trusted di default
        │  (Self-Signed)   │     dal sistema operativo/browser
        └────────┬─────────┘
                 │ firma
        ┌────────▼─────────┐
        │ Intermediate CA  │  ← (opzionale) Firma i certificati finali
        │                  │     senza esporre la Root CA
        └────────┬─────────┘
                 │ firma
        ┌────────▼─────────┐
        │  Leaf Certificate│  ← Certificato del tuo server/client
        │  (End-Entity)    │
        └──────────────────┘
```

### Come funziona la verifica

1. Il client riceve il **Leaf Certificate** del server
2. Controlla chi lo ha firmato (Issuer)
3. Recupera il certificato dell'**Intermediate CA**
4. Verifica la firma dell'Intermediate CA usando la **Root CA**
5. La Root CA è nel **trust store** del sistema → ✅ TRUSTED

Se in un qualsiasi punto la firma non è valida → ❌ `certificate verify failed`

### Trust Store — dove si trovano

| Sistema | Path / Tool |
|---|---|
| **Linux (Ubuntu/Debian)** | `/etc/ssl/certs/` — aggiungere con `update-ca-certificates` |
| **Linux (RHEL/CentOS)** | `/etc/pki/ca-trust/` — aggiungere con `update-ca-trust` |
| **macOS** | Keychain Access |
| **Windows** | `certmgr.msc` |
| **Java / WebLogic** | `$JAVA_HOME/lib/security/cacerts` con `keytool` |
| **Kubernetes** | ConfigMap con CA bundle o Secret TLS |

---

## 3. TLS Handshake step-by-step

Il TLS Handshake è la fase iniziale di ogni connessione HTTPS/TLS. Stabilisce:
- Quale versione TLS usare
- Quale cipher suite usare
- L'autenticazione del server (e opzionalmente del client)
- La chiave simmetrica di sessione (session key)

### TLS 1.2 Handshake

```
CLIENT                                          SERVER
  │                                               │
  │──── ClientHello ──────────────────────────────▶│
  │     (TLS version, cipher suites, random_C)    │
  │                                               │
  │◀─── ServerHello ──────────────────────────────│
  │     (chosen cipher suite, random_S)           │
  │                                               │
  │◀─── Certificate ──────────────────────────────│
  │     (certificato X.509 del server)            │
  │                                               │
  │◀─── ServerHelloDone ──────────────────────────│
  │                                               │
  │  [Client verifica il certificato del server]  │
  │  [Genera Pre-Master Secret (PMS)]             │
  │                                               │
  │──── ClientKeyExchange ────────────────────────▶│
  │     (PMS cifrato con la Public Key del server)│
  │                                               │
  │  [Entrambi derivano la Master Secret]         │
  │  [Da essa: session keys (enc + MAC)]          │
  │                                               │
  │──── ChangeCipherSpec ─────────────────────────▶│
  │──── Finished (cifrato) ───────────────────────▶│
  │                                               │
  │◀─── ChangeCipherSpec ─────────────────────────│
  │◀─── Finished (cifrato) ───────────────────────│
  │                                               │
  │════════════ Dati applicativi cifrati ══════════│
```

### TLS 1.3 Handshake (più veloce — 1-RTT)

```
CLIENT                                          SERVER
  │                                               │
  │──── ClientHello ──────────────────────────────▶│
  │     (key_share, supported_versions,           │
  │      signature_algorithms)                    │
  │                                               │
  │◀─── ServerHello + Certificate ────────────────│
  │◀─── CertificateVerify + Finished ─────────────│
  │                                               │
  │──── Finished ─────────────────────────────────▶│
  │                                               │
  │════════════ Dati applicativi cifrati ══════════│
```

### Differenze TLS 1.2 vs TLS 1.3

| Aspetto | TLS 1.2 | TLS 1.3 |
|---|---|---|
| Round trips | 2-RTT | 1-RTT |
| RSA key exchange | ✅ Supportato | ❌ Rimosso |
| Forward Secrecy | Opzionale | Obbligatoria |
| Cipher suite deboli | RC4, DES, 3DES | Tutti rimossi |
| 0-RTT resumption | ❌ | ✅ (con rischi replay) |

### Derivazione della chiave di sessione

```
Master Secret = PRF(Pre-Master-Secret, "master secret", random_C + random_S)

Da Master Secret si derivano:
  → client_write_key  (cifra i dati dal client)
  → server_write_key  (cifra i dati dal server)
  → client_MAC_key    (integrità messaggi client)
  → server_MAC_key    (integrità messaggi server)
```

> 💡 **Perfect Forward Secrecy (PFS):** Con ECDHE, ogni sessione usa una coppia di chiavi effimera. Se la chiave privata del server viene compromessa in futuro, le sessioni passate non sono decifrabili.

---

## 4. Self-Signed Certificates

Un certificato **self-signed** è firmato dalla stessa entità che lo ha creato (`Subject == Issuer`). È usato per:
- Ambienti di sviluppo e test
- CA interne aziendali (Root CA)
- Kubernetes internal components (API Server, etcd, kubelet)

### Quando usarlo (e quando NO)

| Scenario | Self-Signed? | Alternativa |
|---|---|---|
| Sviluppo locale | ✅ OK | — |
| Test/staging interno | ✅ OK con CA interna | — |
| Produzione pubblica | ❌ | Let's Encrypt / CA commerciale |
| mTLS interno K8s | ✅ OK con CA interna | cert-manager |
| Esposto agli utenti finali | ❌ Browser warning | Let's Encrypt |

### Creare un Self-Signed Certificate (metodo rapido)

```bash
openssl req -x509 -newkey rsa:4096 \
  -keyout key.pem -out cert.pem \
  -days 365 -nodes \
  -subj "/CN=localhost/O=MyOrg/C=IT"
```

---

## 5. Mutual TLS (mTLS)

Nel TLS standard, **solo il server** presenta un certificato al client.  
Con **mTLS (Mutual TLS)**, **anche il client** deve presentare un certificato al server — entrambe le parti si autenticano.

### Flusso mTLS

```
CLIENT                                          SERVER
  │                                               │
  │──── ClientHello ──────────────────────────────▶│
  │                                               │
  │◀─── ServerHello ──────────────────────────────│
  │◀─── Certificate (server cert) ────────────────│
  │◀─── CertificateRequest ───────────────────────│  ← SERVER chiede cert
  │◀─── ServerHelloDone ──────────────────────────│
  │                                               │
  │  [Client verifica cert del server]            │
  │                                               │
  │──── Certificate (client cert) ────────────────▶│  ← CLIENT invia cert
  │──── ClientKeyExchange ────────────────────────▶│
  │──── CertificateVerify ────────────────────────▶│  ← Prova possesso chiave
  │──── ChangeCipherSpec ─────────────────────────▶│
  │──── Finished ─────────────────────────────────▶│
  │                                               │
  │  [Server verifica cert del client]            │
  │                                               │
  │◀─── ChangeCipherSpec ─────────────────────────│
  │◀─── Finished ─────────────────────────────────│
  │                                               │
  │════════════ Dati applicativi cifrati ══════════│
```

### Dove si usa mTLS

- **Kubernetes:** comunicazione tra componenti (API Server ↔ kubelet ↔ etcd)
- **Service Mesh:** Istio, Linkerd (mTLS automatico tra pod)
- **API Gateway:** autenticazione client B2B
- **Zero Trust Network:** ogni servizio si autentica con certificato

### Differenza TLS vs mTLS

| Aspetto | TLS (standard) | mTLS |
|---|---|---|
| Chi si autentica | Solo il server | Server + Client |
| Certificato client | Non richiesto | Obbligatorio |
| Use case | HTTPS pubblico | API B2B, K8s internals, service mesh |
| Complessità | Bassa | Media-Alta |
| Dove in K8s | Ingress esterno | API Server ↔ etcd, Istio |

---

## 6. Comandi OpenSSL essenziali

### Generare una chiave privata
```bash
# RSA 2048-bit
openssl genrsa -out private.key 2048

# RSA con passphrase
openssl genrsa -aes256 -out private.key 2048

# ECDSA (più moderna e leggera)
openssl ecparam -name prime256v1 -genkey -noout -out ec.key
```

### Creare una CSR (Certificate Signing Request)
```bash
openssl req -new -key private.key -out request.csr \
  -subj "/CN=myserver.example.com/O=MyOrg/C=IT"

# Ispeziona la CSR
openssl req -in request.csr -text -noout
```

### Firmare una CSR con una CA
```bash
# Firma base
openssl x509 -req -in request.csr \
  -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out server.crt -days 365 -sha256

# Firma con SAN (obbligatorio per browser moderni)
cat > san.ext << 'EOF'
[SAN]
subjectAltName=DNS:myserver.example.com,DNS:localhost,IP:127.0.0.1
EOF

openssl x509 -req -in request.csr \
  -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out server.crt -days 365 -sha256 \
  -extfile san.ext -extensions SAN
```

### Ispezionare un certificato
```bash
# Visualizza tutto
openssl x509 -in cert.pem -text -noout

# Solo soggetto / issuer / date / fingerprint
openssl x509 -in cert.pem -subject -noout
openssl x509 -in cert.pem -issuer -noout
openssl x509 -in cert.pem -dates -noout
openssl x509 -in cert.pem -fingerprint -sha256 -noout
```

### Verificare la chain of trust
```bash
# Verifica cert con CA
openssl verify -CAfile ca.crt server.crt

# Verifica con chain intermedia
openssl verify -CAfile root-ca.crt -untrusted intermediate.crt server.crt
```

### Testare una connessione TLS
```bash
# Connessione base
openssl s_client -connect myserver.example.com:443 -servername myserver.example.com

# Con client certificate (mTLS)
openssl s_client -connect myserver.example.com:443 \
  -cert client.crt -key client.key \
  -CAfile ca.crt

# Mostra la chain completa
echo | openssl s_client -connect github.com:443 -showcerts 2>/dev/null
```

### Convertire formati
```bash
# PEM → DER
openssl x509 -in cert.pem -outform DER -out cert.der

# DER → PEM
openssl x509 -in cert.der -inform DER -out cert.pem

# PEM → PKCS12 (.p12 / .pfx) — usato da Java/WebLogic/.NET
openssl pkcs12 -export -out bundle.p12 \
  -inkey private.key -in cert.pem -certfile ca.crt

# PKCS12 → PEM
openssl pkcs12 -in bundle.p12 -out extracted.pem -nodes
```

### Verificare che chiave e certificato corrispondano
```bash
# I due hash MD5 devono essere IDENTICI
openssl x509 -noout -modulus -in server.crt | md5sum
openssl rsa  -noout -modulus -in private.key | md5sum
```

### Tabella formati

| Estensione | Formato | Contenuto tipico |
|---|---|---|
| `.pem` | Base64 ASCII | Chiave, cert, o entrambi |
| `.crt` / `.cer` | PEM o DER | Solo certificato |
| `.key` | PEM | Solo chiave privata |
| `.csr` | PEM | Richiesta di firma |
| `.p12` / `.pfx` | PKCS12 binario | Cert + chiave + chain |
| `.der` | DER binario | Cert o chiave |
| `.jks` | Java KeyStore | Usato da Java/WebLogic |

---

> 📝 Vai agli **[Esercizi pratici](./EXERCISES.md)** per mettere in pratica tutto questo.
>
> 📖 Consulta le **[Risorse di studio](./STUDY.md)** per approfondire.
