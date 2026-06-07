# Lab 10 - Debugging TLS

## Obiettivo
Riconoscere, diagnosticare e correggere i problemi TLS più comuni.

## Concetti che impari
- Metodo diagnostico sistematico
- Come leggere gli errori TLS
- Come usare `openssl` per isolare il problema
- Pattern di fix per ogni categoria di errore

## Prerequisiti
- `openssl` installato
- Aver completato lab01-09

## Scenari

| Scenario | Errore simulato |
|----------|-----------------|
| A | Certificato scaduto |
| B | SAN mancante (hostname mismatch) |
| C | Chain incompleta (issuer sconosciuto) |
| D | CA non nel trust store |
| E | Chiave privata non corrisponde al certificato |
| F | mTLS: client cert mancante |

## Come eseguire

```bash
bash solution.sh setup    # genera gli scenari
bash solution.sh debug A  # lavora sullo scenario A
bash solution.sh debug B  # ...
bash verify.sh            # verifica tutti gli scenari
```

## Checklist diagnostica

```
[ ] openssl x509 -in cert.crt -dates -noout              → scaduto?
[ ] openssl x509 -in cert.crt -ext subjectAltName -noout → SAN?
[ ] openssl verify -CAfile ca.crt -untrusted int.crt leaf.crt → chain?
[ ] confronta moduli chiave e cert con md5sum              → coppia?
[ ] openssl s_client -connect host:port -servername host   → handshake?
```
