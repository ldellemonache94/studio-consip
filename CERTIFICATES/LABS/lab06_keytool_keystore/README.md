# Lab 06 - keytool e Keystore

## Obiettivo
Usare `keytool` per creare keystore e truststore, generare una CSR, importare CA e listare alias.

## Concetti che impari
- Differenza tra keystore e truststore in pratica
- Flusso end-to-end con keytool
- Perché PKCS12 è preferibile a JKS
- Come verificare un keystore

## Prerequisiti
- JDK installato (`keytool` disponibile)
- `openssl` per firmare la CSR

## Passi

1. Genera keypair nel keystore PKCS12
2. Crea CSR dal keystore
3. Firma la CSR con openssl (CA locale)
4. Importa la CA nel truststore
5. Importa il cert firmato nel keystore
6. Lista il keystore e verifica

## Errori comuni
- Dimenticare di importare prima la CA e poi il cert firmato
- Alias diverso tra il keypair e il cert importato
- Confondere keystore e truststore nello stesso file
