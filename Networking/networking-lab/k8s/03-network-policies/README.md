# ATTENZIONE AI COMANDI CHE LANCIATE NON MI PRENDO RESPONSABILITA' :)
***
```markdown
# 🟡 03 - NetworkPolicy: blocco e permesso del traffico

**Livello:** Intermedio/Avanzato  
**Strumenti:** `wget`, `curl`, `kubectl`  
**Prerequisito:** CNI che supporta NetworkPolicy (Calico, Cilium, ecc.)

> ⚠️ Se usi minikube con il CNI di default, le NetworkPolicy vengono accettate ma **non applicate**. Usa `minikube start --cni=calico` oppure `kind` con Calico/Cilium.

## Cosa imparerai

- Come funzionano le NetworkPolicy in Kubernetes
- Come bloccare tutto il traffico in ingresso verso un Pod
- Come aprire selettivamente il traffico in base alle label
- Tecnica di troubleshooting per problemi di NetworkPolicy

---

## Setup

```bash
kubectl apply -n lab-networking -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: ealen/echo-server:latest
        ports:
        - containerPort: 80
***
apiVersion: v1
kind: Service
metadata:
  name: backend-svc
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 80
EOF

Ecco il testo **pulito e formattato correttamente in Markdown**:

````markdown
# Esercizio 1 — Senza NetworkPolicy (tutto aperto)

Entra in **net-busybox**:

```bash
kubectl exec -n lab-networking -it net-busybox -- sh
````

Chiama il backend:

```text
wget -qO- --timeout=3 http://backend-svc && echo "OK" || echo "KO"
```

**Risultato atteso:** `OK`
(nessuna policy → tutto consentito).

---

# Esercizio 2 — Blocca tutto il traffico in ingresso

Dalla tua macchina, applica una **deny-all policy**:

```bash
kubectl apply -n lab-networking -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress-backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
EOF
```

Rientra in **net-busybox** e riprova:

```text
wget -qO- --timeout=3 http://backend-svc && echo "OK" || echo "KO"
```

### Domande

* Cosa vedi ora? **Timeout** o **connection refused**?
* Perché il **Service esiste ancora** ma non risponde?
* Come verificheresti da fuori che il problema è la **NetworkPolicy** e non il Pod?

<details>
<summary>💡 Risposta</summary>

```bash
# Verifica NetworkPolicy attive
kubectl get networkpolicies -n lab-networking

# Verifica che il Pod backend sia Running
kubectl get pods -n lab-networking -l app=backend

# Verifica gli Endpoints
kubectl get endpoints backend-svc -n lab-networking
```

Il Pod è **Running** e gli **Endpoints esistono** → il problema è la **NetworkPolicy**.

</details>

---

# Esercizio 3 — Permetti solo da Pod con label specifica

Assegna una label al Pod di test:

```bash
kubectl label pod net-busybox -n lab-networking access=allowed
```

Sostituisci la **NetworkPolicy**:

```bash
kubectl apply -n lab-networking -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress-backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          access: allowed
    ports:
    - protocol: TCP
      port: 80
EOF
```

Test dal Pod **net-busybox** (`access=allowed`):

```text
wget -qO- --timeout=3 http://backend-svc && echo "OK" || echo "KO"
```

Crea un secondo Pod **senza label**:

```bash
kubectl run net-test \
  -n lab-networking \
  --image=busybox:1.36 \
  --restart=Never \
  --command -- sh -c "sleep 3600"
```

Test dal Pod **net-test** (nessuna label):

```bash
kubectl exec -n lab-networking -it net-test -- sh
```

```text
wget -qO- --timeout=3 http://backend-svc && echo "OK" || echo "KO"
```

### Domande

* Perché **net-busybox** riesce e **net-test** no?
* Come verificheresti le **label di un Pod**?
* Modifica la **NetworkPolicy** per permettere anche `net-test`.

---

# Cleanup

```bash
kubectl delete deployment backend -n lab-networking
kubectl delete service backend-svc -n lab-networking
kubectl delete networkpolicy deny-all-ingress-backend -n lab-networking
kubectl delete pod net-test -n lab-networking
```