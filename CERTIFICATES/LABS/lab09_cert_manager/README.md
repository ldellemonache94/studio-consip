# Lab 09 - cert-manager

## Obiettivo
Usare cert-manager per emettere e rinnovare automaticamente certificati in un cluster Kubernetes.

## Concetti che impari
- Pattern bootstrap CA interna
- Differenza tra `Issuer` e `ClusterIssuer`
- Come un `Certificate` diventa un Secret TLS
- Rinnovo automatico

## Prerequisiti
- cluster Kubernetes (Kind/minikube)
- cert-manager installato: `kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml`
- `cmctl` (opzionale, per forzare rinnovo)

## Passi

1. Crea `ClusterIssuer` self-signed (bootstrap)
2. Crea `Certificate` per la CA interna (`isCA: true`)
3. Crea `ClusterIssuer` che usa la CA interna
4. Crea `Certificate` per il workload
5. Verifica il Secret TLS generato
6. Forza rinnovo e verifica

## Errori comuni
- Issuer in namespace sbagliato
- `secretName` CA non accessibile dal ClusterIssuer
- Pod non riavviato dopo rinnovo del Secret
