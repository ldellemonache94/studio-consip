# Esercizio CKAD 2: CronJob Batch con PVC e InitContainer

## Obiettivo
CronJob che scrive log persistenti su PVC, con initContainer per setup e comandi debug (stile CKAD: volumi, scheduling, troubleshooting).

## Setup Minikube su WSL
Vedi Esercizio 1 (usa lo stesso cluster, per vedere se è running: `minikube status`).

## Esecuzione Esercizio
1. Crea namespace:
```bash
k create ns ckad-jobs
k config set-con  --current --namespace=ckad-jobs
```

2. Applica manifest:
```bash
k apply -f .
```

3. Verifica:
```bash
k get cronjob,pvc
k get jobs,pod # Job generati dal CronJob
k describe cronjob log-writer # Schedule, status
k logs job/<nome-job> # Log specifico job
```

4. Forza esecuzione immediata:
```bash
k create job manual-log --from=cronjob/log-writer
k logs job/manual-log # Verifica output su PVC
```

5. Debug fallimento simulato (cancella PVC, riapplica, descrivi):
```bash
k describe pod # Events per mount errors
k exec pod/<nome> -- cat /data/output.log # Leggi PVC
```

## Pulizia
```bash
k delete ns ckad-jobs
```
## Note CKAD
- Tempo stimato: 15 min.
- PVC usa storageclass di Minikube (`standard`), dati persistono tra job.
- Debug: `k describe` prima di tutto per root cause.