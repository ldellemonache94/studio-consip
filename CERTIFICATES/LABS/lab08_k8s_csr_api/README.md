# Lab 08 - Kubernetes CSR API

## Obiettivo
Usare la Certificates API di Kubernetes per emettere un certificato firmato dalla CA del cluster.

## Concetti che impari
- Come funziona la risorsa `CertificateSigningRequest`
- Flusso: genera chiave → CSR → risorsa K8s → approva → scarica cert
- Differenza tra i signer built-in
- Come usare il certificato ottenuto

## Prerequisiti
- `kubectl` configurato con accesso a un cluster (Kind/minikube OK)
- `openssl` installato

## Passi
1. Genera chiave RSA
2. Genera CSR PKCS#10
3. Crea la risorsa `CertificateSigningRequest` in Kubernetes
4. Approva con `kubectl certificate approve`
5. Scarica il certificato da `status.certificate`
6. Verifica il certificato

## Errori comuni
- `signerName` sbagliato → signer non firma
- Base64 della CSR con newline → errore di parsing
- Permessi insufficienti per approvare → verifica RBAC
