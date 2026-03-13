# ATTENZIONE AI COMANDI CHE LANCIATE NON MI PRENDO RESPONSABILITA' :)
***
# ☸️ Kubernetes Networking Lab

Esercizi di networking da eseguire **dall'interno di un Pod** Kubernetes.

## Obiettivi del percorso

- Capire come funziona il DNS interno al cluster (CoreDNS)
- Testare la raggiungibilità tra Pod e Service
- Capire l'effetto delle NetworkPolicy
- Diagnosticare problemi di connettività reali
- Costruire una checklist di troubleshooting

## Struttura esercizi

| Cartella | Argomento | Livello |
|---|---|---|
| `01-basic-dns-curl/` | DNS base e curl dentro un Pod | 🟢 Base |
| `02-services-endpoints/` | Service, Endpoints, load balancing | 🟡 Intermedio |
| `03-network-policies/` | NetworkPolicy: blocco e permesso traffico | 🟡 Intermedio |
| `04-external-connectivity/` | Uscita verso Internet dal Pod | 🔴 Avanzato |
| `05-advanced-debug/` | Checklist debug avanzato | 🔴 Avanzato |


## Setup iniziale (fare UNA VOLTA sola)

### 1. Crea il namespace di test

```bash
kubectl create namespace lab-networking
```

### 2. Avvia il Pod di test busybox
```bash
kubectl run net-busybox \
  -n lab-networking \
  --image=busybox:1.36 \
  --restart=Never \
  --command -- sh -c "sleep 3600"
```

### 3. Avvia il Pod di test netshoot (strumenti avanzati)
```bash
kubectl run net-netshoot \
  -n lab-networking \
  --image=nicolaka/netshoot \
  --restart=Never \
  --command -- sleep 3600
```

### 4. Verifica che i Pod siano Running
```bash
kubectl get pods -n lab-networking
```

#### Output atteso:

```text
NAME            READY   STATUS    RESTARTS
net-busybox     1/1     Running   0
net-netshoot    1/1     Running   0
```

### 5. Come entrare nei Pod
```bash
# Entra in busybox (shell sh)
kubectl exec -n lab-networking -it net-busybox -- sh
# Entra in netshoot (shell bash, più strumenti)
kubectl exec -n lab-networking -it net-netshoot -- bash
```

#### Cleanup finale (dopo tutti gli esercizi)
```bash
kubectl delete namespace lab-networking
```