# ATTENZIONE AI COMANDI CHE LANCIATE NON MI PRENDO RESPONSABILITA' :)
***
# 🔴 05 - Debug avanzato: checklist e scenari reali

**Livello:** Avanzato  
**Strumenti:** tutti i precedenti  
**Prerequisito:** Esercizi 01-04 completati

## Cosa imparerai

- Costruire una checklist sistematica di troubleshooting
- Diagnosticare problemi reali seguendo un approccio a livelli
- Scrivere uno script di debug riutilizzabile

---

## La checklist sistematica

Quando un colleghi ti dice *"il Pod non riesce a chiamare il servizio X"*, segui questo ordine:

- Il **Pod è Running?** → `kubectl get pod`
- Il **Service esiste?** → `kubectl get svc`
- Gli **Endpoints sono ok?** → `kubectl get endpoints`
- Il **DNS risolve?** → `nslookup <service-name>`
- La **porta è raggiungibile?** → `nc -zv <IP> <PORT>`
- **HTTP risponde?** → `curl -v http://<service>`
- **NetworkPolicy bloccano?** → `kubectl get networkpolicies`

---

# Esercizio 1 — Scenario guasto: Service senza Endpoints

Crea un **Service con selector sbagliato**:

```bash
kubectl apply -n lab-networking -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: broken-svc
spec:
  selector:
    app: questo-non-esiste
  ports:
  - port: 80
    targetPort: 80
EOF
````

Entra nel Pod e prova a chiamarlo:

```bash
kubectl exec -n lab-networking -it net-busybox -- sh
wget -qO- --timeout=3 http://broken-svc && echo "OK" || echo "KO"
```

Diagnostica:

```bash
kubectl get endpoints broken-svc -n lab-networking
```

### Domande

* Cosa vedi negli **Endpoints**?
* Come capiresti che il problema è il **selector sbagliato**?
* Qual è la differenza tra **Connection refused** e **Timeout**?

<details>
<summary>💡 Risposta</summary>

Endpoints vuoti (`<none>`) → il selector non matcha nessun Pod.

* **Timeout** → il Service esiste, kube-proxy instrada ma non c'è nessun Pod.
* **Connection refused** → il Pod c'è ma la porta non è in ascolto.

</details>

---

# Esercizio 2 — Scenario guasto: porta sbagliata

```bash
kubectl apply -n lab-networking -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wrong-port-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: wrong-port-app
  template:
    metadata:
      labels:
        app: wrong-port-app
    spec:
      containers:
      - name: app
        image: ealen/echo-server:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: wrong-port-svc
spec:
  selector:
    app: wrong-port-app
  ports:
  - port: 80
    targetPort: 9999
EOF
```

Entra nel Pod e testa:

```bash
kubectl exec -n lab-networking -it net-busybox -- sh
wget -qO- --timeout=3 http://wrong-port-svc && echo "OK" || echo "KO"
```

### Domande

* Gli **Endpoints** sono presenti?
* Cosa vedi quando provi a connetterti?
* Come identifichi che il **targetPort è sbagliato**?

---

# Esercizio 3 — Script di debug universale

Dalla tua macchina, crea questo script `k8s-net-debug.sh`:

```bash
#!/usr/bin/env bash
# Uso: ./k8s-net-debug.sh <SERVICE_NAME> <NAMESPACE>

SVC=$1
NS=${2:-default}

echo "======================================"
echo " K8s Network Debug: $SVC / $NS"
echo "======================================"

echo ""
echo "--- Service ---"
kubectl get svc "$SVC" -n "$NS" -o wide 2>/dev/null || echo "❌ Service non trovato"

echo ""
echo "--- Endpoints ---"
kubectl get endpoints "$SVC" -n "$NS" 2>/dev/null || echo "❌ Endpoints non trovati"

echo ""
echo "--- Pod selezionati ---"
SELECTOR=$(kubectl get svc "$SVC" -n "$NS" -o jsonpath='{.spec.selector}' 2>/dev/null)
echo "Selector: $SELECTOR"

echo ""
echo "--- NetworkPolicy in namespace $NS ---"
kubectl get networkpolicies -n "$NS" 2>/dev/null

echo ""
echo "======================================"
```

Esegui:

```bash
chmod +x k8s-net-debug.sh
./k8s-net-debug.sh broken-svc lab-networking
./k8s-net-debug.sh wrong-port-svc lab-networking
```

---

# Esercizio 4 — Costruisci il tuo runbook

Scrivi su carta (o in un nuovo file `RUNBOOK.md`) la risposta a questo scenario:

> "Un microservizio in produzione smette improvvisamente di rispondere alle chiamate degli altri Pod. I log del Pod sembrano normali. Cosa fai?"

Il **runbook** deve includere **almeno 8 step** con i relativi comandi.

---

# Cleanup finale Kubernetes

```bash
kubectl delete namespace lab-networking
```
