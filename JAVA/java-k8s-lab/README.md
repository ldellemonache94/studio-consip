# 🚀 JVM on Kubernetes Lab

Questo repository è un laboratorio pratico per capire come funziona la JVM dentro Kubernetes:

* memoria (heap vs container)
* CPU e throttling
* Garbage Collector (Shenandoah)
* OOM (Java vs Kubernetes)

👉 Pensato per DevSecOps / Platform Engineers

---

# ⚡ Quick Start

## 1. Avvia Minikube

```bash
minikube start --memory=8192 --cpus=4
eval $(minikube docker-env)
```

## 2. Build immagine

```bash
cd app
docker build -t memory-eater:latest .
```

## 3. Deploy base

```bash
kubectl apply -f k8s/deployment.yaml
```

---

# 🧪 Esercizi inclusi

| Scenario           | File                       |
| ------------------ | -------------------------- |
| No Xmx → OOMKilled | deployment.yaml            |
| Heap limitato      | deployment-xmx.yaml        |
| Shenandoah GC      | deployment-shenandoah.yaml |

---

# 🔍 Comandi utili

```bash
kubectl get pods
kubectl logs -f <pod>
kubectl describe pod <pod>
kubectl top pod
```

---

# 🧠 Cosa impari

* differenza tra:

  * OOMKilled (Kubernetes)
  * OutOfMemoryError (Java)
* dimensionamento heap
* impatto CPU limits
* comportamento GC

---

# 📦 Helm (opzionale)

```bash
cd helm/memory-eater
helm install mem-test .
```

---

# 🔜 Next step

👉 Vai su:

* `README-springboot.md` → versione realistica con Spring Boot
* cartella `springboot/`

---

# 🧠 Regola chiave

> Kubernetes limita il processo.
> La JVM decide COME usare quel limite.

---

Buon laboratorio 💥
