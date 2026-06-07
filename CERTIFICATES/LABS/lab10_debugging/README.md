# Lab 10 - Debugging TLS

## Obiettivo
Riconoscere, diagnosticare e correggere i problemi TLS più comuni.

## Scenari

| Scenario | Errore simulato |
|----------|-----------------|
| A | Certificato scaduto |
| B | SAN mancante (hostname mismatch) |
| C | Chain incompleta (issuer sconosciuto) |
| D | CA non nel trust store |
| E | Chiave privata non corrisponde al certificato |

## Come eseguire

```bash
# Setup: genera tutti gli scenari
bash solution.sh setup

# Lavora su ogni scenario
bash solution.sh debug A
bash solution.sh debug B
bash solution.sh debug C
bash solution.sh debug D
bash solution.sh debug E

# Verifica il setup
bash verify.sh
```

## Checklist diagnostica

```
[ ] openssl x509 -in cert.crt -dates -noout              → scaduto?
[ ] openssl x509 -in cert.crt -ext subjectAltName -noout → SAN?
[ ] openssl verify -CAfile ca.crt -untrusted int.crt leaf.crt → chain?
[ ] confronta moduli chiave e cert con md5sum             → coppia?
[ ] openssl s_client -connect host:port -servername host  → handshake?
```
