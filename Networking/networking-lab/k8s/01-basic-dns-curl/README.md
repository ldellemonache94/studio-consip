# ATTENZIONE AI COMANDI CHE LANCIATE NON MI PRENDO RESPONSABILITA' :)
***
```markdown
# 🟢 01 - DNS di base e curl dentro un Pod

**Livello:** Base  
**Strumenti:** `nslookup`, `wget`, `curl`, `cat`  
**Prerequisito:** Setup iniziale completato (vedi `k8s/README.md`)

## Cosa imparerai

- Come funziona il DNS in Kubernetes
- Come un Pod risolve i nomi dei Service
- Come usare `curl`/`wget` per chiamare un Service dall'interno del cluster
- Cosa contiene `/etc/resolv.conf` in un Pod

---

## Setup: deploy del servizio di test

Crea un Deployment con 2 repliche + un Service HTTP.  
Esegui questo comando dalla tua macchina (non dentro il Pod):

```bash
kubectl apply -n lab-networking -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo-server
spec:
  replicas: 2
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
    protocol: TCP
EOF

````markdown
## Verifica

```bash
kubectl get pods,svc -n lab-networking
````

---

# Esercizio 1 — Risolvi il nome del Service via DNS

Entra nel Pod **busybox**:

```bash
kubectl exec -n lab-networking -it net-busybox -- sh
```

Ora, dentro il Pod, esegui:

```text
nslookup echo-svc
nslookup echo-svc.lab-networking.svc.cluster.local
```

### Domande

* Che indirizzo IP restituisce `nslookup echo-svc`?
* È lo stesso IP del **ClusterIP** del Service?
  (verifica con:)

```bash
kubectl get svc echo-svc -n lab-networking
```

* Perché funziona anche con il nome corto `echo-svc` senza il **FQDN**?

<details>
<summary>💡 Risposta</summary>

Il Pod usa **CoreDNS** come resolver (vedi `/etc/resolv.conf`).

Il file `resolv.conf` contiene i **search domain**, tra cui:

```
lab-networking.svc.cluster.local
```

Kubernetes completa automaticamente il nome corto con questi **search domain**.

</details>

---

# Esercizio 2 — Leggi /etc/resolv.conf

Sempre dentro il Pod `net-busybox`:

```text
cat /etc/resolv.conf
```

### Domande

* Qual è l'IP del **nameserver**?
  (sarà qualcosa come `10.96.0.10`)

* Quali **search domain** sono configurati?

* Quanti livelli di ricerca ci sono?

<details>
<summary>💡 Risposta</summary>

Output tipico:

```text
nameserver 10.96.0.10
search lab-networking.svc.cluster.local svc.cluster.local cluster.local
options ndots:5
```

`10.96.0.10` è l'IP del Service **kube-dns** nel namespace `kube-system` (CoreDNS).

</details>

---

# Esercizio 3 — Chiama il Service con wget e curl

Dentro `net-busybox`:

```text
wget -qO- http://echo-svc
wget -qO- http://echo-svc.lab-networking.svc.cluster.local
```

Dentro `net-netshoot` (ha **curl**):

```bash
kubectl exec -n lab-networking -it net-netshoot -- bash
```

```bash
curl http://echo-svc
curl -v http://echo-svc
```

### Domande

* Quale **hostname** vedi nel JSON di risposta?
  (sarà il nome del Pod che ha risposto)

* Cambia ad ogni chiamata? Perché?

* Cosa mostra il flag `-v` in più rispetto alla versione senza?

---

# Esercizio 4 — Risoluzione DNS fallita (errori comuni)

Dentro `net-busybox`, prova questi comandi **sbagliati**:

```text
nslookup echo-svc.default.svc.cluster.local
wget -qO- --timeout=3 http://echo-svc.default.svc.cluster.local || echo "ERRORE!"
```

### Domande

* Perché fallisce?
* Come lo risolveresti?

<details>
<summary>💡 Risposta</summary>

Il Service si trova nel namespace **lab-networking**, non in `default`.

Il **FQDN corretto** è:

```
echo-svc.lab-networking.svc.cluster.local
```

In Kubernetes, i Service **non sono visibili cross-namespace semplicemente con il nome corto**.

</details>

---

# Cleanup esercizio

```bash
kubectl delete deployment echo-server -n lab-networking
kubectl delete service echo-svc -n lab-networking
```

```

Se vuoi, posso anche trasformarlo in una **dispensa da laboratorio Kubernetes molto più leggibile (stile training DevOps)** con:
- diagramma del DNS Kubernetes
- spiegazione visiva di CoreDNS
- flow DNS → Service → Pod.
```