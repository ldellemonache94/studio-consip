# App – MemoryEater

Applicazione Java minimale per simulare consumo memoria.

## Build

```bash
docker build -t memory-eater:latest .
```
```bash
java MemoryEater
```

---

# ☸️ KUBERNETES

---

## 📁 `k8s/namespace.yaml`

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: jvm-lab
```