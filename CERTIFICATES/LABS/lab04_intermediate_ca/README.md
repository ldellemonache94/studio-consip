# Lab 04 - Intermediate CA

## Obiettivo
Costruire una catena di trust a **3 livelli**: Root CA → Intermediate CA → Leaf certificate.

## Concetti che impari
- Differenza tra Root CA e Intermediate CA
- `CA:TRUE` vs `CA:FALSE` nel campo Basic Constraints
- Come verificare una chain completa
- Perché in produzione si usa sempre un'Intermediate CA

## Prerequisiti
- `openssl` installato
- Aver completato lab01-03

## Passi
1. Crea Root CA (self-signed, CA:TRUE, pathlen:1)
2. Crea Intermediate CA (firmata dalla Root CA, CA:TRUE, pathlen:0)
3. Crea chiave e CSR per il server
4. Firma la CSR con l'Intermediate CA
5. Costruisci il chain file: `cat server.crt intermediate.crt > chain.pem`
6. Verifica la chain completa

## Deliverable attesi
```
root-ca.key / root-ca.crt
intermediate-ca.key / intermediate-ca.crt / intermediate-ca.csr
server.key / server.csr / server.crt
chain.pem
```

## Errori comuni
- Dimenticare `pathlen:0` sull'Intermediate
- Verificare solo con la Root CA senza passare l'Intermediate come `-untrusted`
- Non includere i SAN nel server cert

## Cosa hai imparato
- Root CA non emette mai leaf direttamente in produzione
- L'Intermediate CA limita il blast radius di una compromissione
- La chain completa deve essere inviata dal server al client
