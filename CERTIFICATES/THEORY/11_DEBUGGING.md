# 11 - Debugging TLS e Certificati

## Metodo diagnostico

Seguire sempre questo ordine:

```
1. Leggi il messaggio di errore esatto
2. Identifica la categoria (identity / trust / validity / protocol / mTLS)
3. Verifica il certificato localmente con openssl
4. Verifica la chain
5. Simula il handshake con openssl s_client
6. Correggi e verifica di nuovo
```

---

## Errori comuni → causa → fix

### identity problems

| Errore | Causa | Fix |
|--------|-------|-----|
| `x509: certificate is valid for foo.com, not bar.com` | hostname mismatch | rigenera cert con SAN corretto |
| `x509: certificate relies on legacy Common Name field` | SAN mancante (Go 1.15+) | aggiungi SAN al cert |
| `SSL: no alternative certificate subject name matches` | SAN non copre l'hostname | aggiungi hostname/IP tra i SAN |

### trust problems

| Errore | Causa | Fix |
|--------|-------|-----|
| `x509: certificate signed by unknown authority` | CA non nel trust store | importa la CA nel trust store |
| `unable to get local issuer certificate` | chain incompleta | invia l'intermediate con il server cert |
| `certificate verify failed (unable to get issuer cert)` | issuer mancante | serve la chain completa |
| `self-signed certificate in certificate chain` | self-signed non trusted | aggiungi la CA al trust store |

### validity problems

| Errore | Causa | Fix |
|--------|-------|-----|
| `certificate has expired or is not yet valid` | cert scaduto o data sistema errata | rinnova cert o correggi orologio |
| `notBefore` nel futuro | cert non ancora valido | controlla il clock del sistema |

### protocol / cipher problems

| Errore | Causa | Fix |
|--------|-------|-----|
| `wrong version number` | TLS version mismatch | allinea versioni TLS |
| `no shared cipher` / `handshake failure` | cipher suite incompatibili | allinea cipher suite |
| `tlsv1 alert protocol version` | client o server usa versione TLS non supportata | abilita versioni compatibili |
| `SNI mismatch` | SNI assente o errato | passa `-servername` oppure configura SNI |

### mTLS problems

| Errore | Causa | Fix |
|--------|-------|-----|
| `tls: certificate required` | server richiede client cert ma non l'hai passato | passa `-cert` e `-key` |
| `tls: bad certificate` | client cert non valido o firma non riconosciuta | verifica che la CA del client cert sia nel server trust store |
| `unknown ca` | CA del client cert non nel server truststore | importa CA client nel truststore server |

---

## Comandi diagnostici

### Ispeziona un certificato
```bash
# Da file
openssl x509 -in server.crt -text -noout

# Da server (senza file)
echo | openssl s_client -connect api.example.com:443 -servername api.example.com 2>/dev/null | openssl x509 -text -noout

# Solo date
openssl x509 -in server.crt -dates -noout

# Solo SAN
openssl x509 -in server.crt -ext subjectAltName -noout

# Solo subject e issuer
openssl x509 -in server.crt -subject -issuer -noout
```

### Verifica chain
```bash
# Solo leaf + root
openssl verify -CAfile ca.crt server.crt

# Leaf + intermediate + root
openssl verify -CAfile ca.crt -untrusted intermediate.crt server.crt

# Con chain file (bundle)
cat intermediate.crt ca.crt > chain-bundle.crt
openssl verify -CAfile chain-bundle.crt server.crt
```

### Test handshake TLS completo
```bash
# Base
openssl s_client -connect api.example.com:443 -servername api.example.com

# Mostra chain completa
openssl s_client -connect api.example.com:443 -servername api.example.com -showcerts

# Verifica ritorno errore
openssl s_client -connect api.example.com:443 -servername api.example.com -verify_return_error

# Forza TLS 1.2
openssl s_client -connect api.example.com:443 -tls1_2

# mTLS: client si autentica
openssl s_client -connect api.example.com:443 \
  -servername api.example.com \
  -cert client.crt \
  -key client.key \
  -CAfile ca.crt
```

### Decodifica CSR
```bash
openssl req -in myapp.csr -text -noout
```

### Verifica certificato in un Secret Kubernetes
```bash
kubectl get secret myapp-tls -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout

# Scadenza
kubectl get secret myapp-tls -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -dates -noout
```

### Check revoca CRL
```bash
# Scarica CRL da AIA del certificato
CRL_URL=$(openssl x509 -in server.crt -noout -text | grep -A2 'CRL Distribution' | grep URI | sed 's/.*URI://')
wget -q -O crl.der "$CRL_URL"
openssl crl -inform DER -in crl.der -text -noout
```

---

## Kubernetes: scenari tipici

### Cert scaduto nel control plane
```bash
kubeadm certs check-expiration
kubeadm certs renew all
# Riavvia i componenti static pod
kill -s SIGHUP $(pidof kube-apiserver)
```

### Secret TLS errato
```bash
# Verifica che tls.crt e tls.key siano coerenti
kubectl get secret myapp-tls -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout -modulus | md5sum
kubectl get secret myapp-tls -o jsonpath='{.data.tls\.key}' | base64 -d | openssl rsa -noout -modulus | md5sum
# I due hash devono essere uguali
```

### cert-manager non rinnova
```bash
kubectl describe certificate myapp-cert
kubectl describe certificaterequest -l cert-manager.io/certificate-name=myapp-cert
kubectl logs -n cert-manager deployment/cert-manager
```

### CSR non approvata
```bash
kubectl get csr
kubectl describe csr myapp-csr  # leggi Events e Conditions
kubectl certificate approve myapp-csr
```

---

## Checklist rapida

```
[ ] Il cert è scaduto?         → openssl x509 -dates
[ ] SAN copre l'hostname?      → openssl x509 -ext subjectAltName
[ ] Chain completa?            → openssl verify -CAfile ca.crt -untrusted int.crt server.crt
[ ] CA nel trust store?        → openssl s_client ... 2>&1 | grep 'Verify return code'
[ ] Chiave e cert fanno coppia? → confronta moduli con md5sum
[ ] TLS version OK?            → openssl s_client -tls1_2 / -tls1_3
[ ] mTLS: client cert passato? → openssl s_client -cert -key -CAfile
[ ] Kubernetes: Secret TLS OK? → kubectl get secret ... | base64 -d | openssl x509
[ ] cert-manager: eventi OK?   → kubectl describe certificate
```

---

## Flash quiz

1. Qual è il primo passo del metodo diagnostico?
2. Quale errore indica che la CA non è nel trust store?
3. Come verifichi che chiave privata e certificato facciano coppia?
4. Come simuli un client mTLS con openssl?
5. Come verifichi la scadenza di un certificato dentro un Secret Kubernetes?
