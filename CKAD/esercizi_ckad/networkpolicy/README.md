# Esercizio CKAD 7 – NetworkPolicy

## Obiettivo
Capire come isolare il traffico di rete tra Pod usando NetworkPolicy:
deny-all di default, whitelist selettiva per namespace e label.

**Difficoltà:** ⭐⭐⭐ (intermedio)  
**Dominio CKAD:** Services and Networking (20%)  
**Tempo stimato:** 25 min

---

## Scenario
Hai tre namespace:
- `ckad-frontend`: app frontend (nginx)
- `ckad-backend`: app backend (nginx)
- `ckad-db`: database simulato (nginx)

Regole da implementare:
1. Di default **nessuno** può parlare con `ckad-db`
2. Solo i pod di `ckad-backend` possono raggiungere `ckad-db` sulla porta 80
3. Solo i pod di `ckad-frontend` possono raggiungere `ckad-backend` sulla porta 80
4. `ckad-frontend` è raggiungibile da chiunque

---

## Setup Minikube
```bash
minikube start --driver=docker
# Abilita CNI plugin (necessario per NetworkPolicy su Minikube)
minikube start --driver=docker --cni=calico
# oppure con un cluster già avviato:
# Le NetworkPolicy richiedono un CNI che le supporti (Calico, Cilium, Weave)
```

> ⚠️ Il CNI di default di Minikube (kindnet) non applica NetworkPolicy.
> Avvia Minikube con `--cni=calico` per testare correttamente.

---

## Step 1 – Crea namespace e pod
```bash
k apply -f manifest/namespaces.yaml
k apply -f manifest/pods.yaml
k get pods -A | grep ckad
```

---

## Step 2 – Verifica connettività iniziale (tutto aperto)
```bash
# Dal frontend, raggiungi backend e db
k exec -n ckad-frontend pod/frontend -- wget -qO- --timeout=2 http://backend.ckad-backend
k exec -n ckad-frontend pod/frontend -- wget -qO- --timeout=2 http://db.ckad-db
# Entrambi devono rispondere: connessione aperta
```

---

## Step 3 – Applica NetworkPolicy
```bash
k apply -f manifest/networkpolicies.yaml
k get networkpolicy -A
```

---

## Step 4 – Verifica isolamento
```bash
# Frontend → Backend: deve funzionare ✅
k exec -n ckad-frontend pod/frontend -- wget -qO- --timeout=2 http://backend.ckad-backend

# Frontend → DB: deve fallire (timeout) ❌
k exec -n ckad-frontend pod/frontend -- wget -qO- --timeout=2 http://db.ckad-db

# Backend → DB: deve funzionare ✅
k exec -n ckad-backend pod/backend -- wget -qO- --timeout=2 http://db.ckad-db
```

---

## Step 5 – Pulizia
```bash
k delete ns ckad-frontend ckad-backend ckad-db
```
---

## Domande di verifica
1. Cosa fa una NetworkPolicy con `podSelector: {}` e nessuna regola `ingress`?
2. Qual è la differenza tra `podSelector` e `namespaceSelector`?
3. Perché senza CNI compatibile le NetworkPolicy non funzionano?
4. Come verificheresti quale traffico è bloccato con `kubectl describe networkpolicy`?
```