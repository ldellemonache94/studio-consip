# ATTENZIONE AI COMANDI CHE LANCIATE NON MI PRENDO RESPONSABILITA' :)
***
```markdown
# 🟡 02 - Service, Endpoints e Load Balancing

**Livello:** Intermedio  
**Strumenti:** `curl`, `jq`, `kubectl`  
**Prerequisito:** Esercizio 01 completato

## Cosa imparerai

- Differenza tra Service IP (ClusterIP) e Pod IP (Endpoint)
- Come il traffico viene bilanciato tra le repliche
- Come accedere direttamente a un Pod bypassando il Service
- NodePort e come esporre un servizio verso l'esterno

---

## Setup

```bash
kubectl apply -n lab-networking -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo-server
spec:
  replicas: 3
  selector:
    matchLabels:
      app: echo-server
  template:
    metadata:
      labels:
        app: echo-server
    spec:
      containers:
      - name: echo-server
        image: ealen/echo-server:latest
        ports:
        - containerPort: 80
***
apiVersion: v1
kind: Service
metadata:
  name: echo-svc
spec:
  selector:
    app: echo-server
  ports:
  - port: 80
    targetPort: 80
EOF

Ecco il testo **formattato correttamente in Markdown**:

````markdown
# Esercizio 1 — Ispeziona Service ed Endpoints

Dalla tua macchina:

```bash
kubectl get svc echo-svc -n lab-networking -o wide
kubectl get endpoints echo-svc -n lab-networking -o wide
kubectl get pods -n lab-networking -o wide -l app=echo-server
````

### Domande

* Quanti IP vedi nella colonna **ENDPOINTS**?
* Corrispondono agli IP dei **Pod**?
* Cosa succede agli Endpoints se un Pod crasha?
  (elimina un Pod con:)

```bash
kubectl delete pod <nome>
```

poi ricontrolla.

---

# Esercizio 2 — ClusterIP vs Pod IP diretto

Dalla tua macchina, recupera gli IP:

```bash
kubectl get endpoints echo-svc -n lab-networking -o jsonpath='{.subsets[*].addresses[*].ip}'
```

Entra in **net-netshoot**:

```bash
kubectl exec -n lab-networking -it net-netshoot -- bash
```

Dentro il Pod:

```text
# Test via Service (ClusterIP)
curl -s http://echo-svc | grep hostname

# Test diretto via Pod IP (sostituisci con un IP reale)
curl -s http://<POD_IP> | grep hostname
```

### Domande

* Qual è la differenza pratica tra i due approcci?
* In quale scenario vorresti **bypassare il Service** e chiamare direttamente il Pod?

---

# Esercizio 3 — Osserva il load balancing

Dentro **net-netshoot**:

```text
for i in $(seq 1 12); do
  curl -s http://echo-svc | grep -o '"hostname":"[^"]*"'
done
```

### Domande

* Quanti **Pod diversi** rispondono?
* Il traffico è distribuito **uniformemente**?
* È **round-robin** o **random**?

---

# Esercizio 4 — NodePort

Dalla tua macchina, converti il Service in **NodePort**:

```bash
kubectl patch svc echo-svc -n lab-networking \
  -p '{"spec": {"type": "NodePort"}}'

kubectl get svc echo-svc -n lab-networking
```

Annota la **NodePort** (es. `30080`) e l'IP del nodo:

```bash
kubectl get nodes -o wide
```

Dentro **net-netshoot**, chiama il Service via **NodePort**:

```text
curl http://<NODE_IP>:<NODEPORT>
```

### Domande

* Funziona? Rispondi da quale **Pod**?
* Qual è la differenza tra **ClusterIP** e **NodePort** in termini di accessibilità?

---

# Cleanup

```bash
kubectl delete deployment echo-server -n lab-networking
kubectl delete service echo-svc -n lab-networking
```