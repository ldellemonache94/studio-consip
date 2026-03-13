# Esercizio CKAD 1: Deploy WebApp con ConfigMap, Secret, Probes e Service

## Obiettivo
Deploy di un'app HTTP stateless con best practices CKAD: namespace dedicato, risorse limitate, probes per health check, config/secret montati e service esposto.

## Setup Minikube su WSL (5-10 min, fai solo la prima volta)
1. Apri WSL (Ubuntu):
```bash
sudo apt update && sudo apt install -y docker.io kubectl curl
sudo usermod -aG docker $USER # Riavvia WSL dopo
```

2. Installa Minikube:
```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

3. Avvia cluster:
```bash
minikube start --driver=docker --cpus=2 --memory=4096 #non serve usare solo minikube start
```
- Usa `--driver=docker` per WSL, alloca 2 CPU/4GB RAM per probes/deploy fluido.

4. Verifica:
```bash
kubectl get nodes # Deve mostrare minikube Ready
alias k=kubectl # Shortcut CKAD-style
```

## Esecuzione Esercizio
1. Crea namespace:
```bash
k create ns ckad-webapp
k config set-con --current --namespace=ckad-webapp
```

2. Applica manifest (copia YAML da `manifest/`):
```bash
k apply -f .
```

3. Verifica:
```bash
k get deploy,svc,pod
k describe pod # Controlla probes/events
k logs deploy/webapp -f # Log rollout
k port-forward svc/webapp 8080:80 # Testa local: curl localhost:8080
```
 
4. Rollout update (cambia image in YAML, es. nginx:1.16):
```bash
k rollout status deploy/webapp
k rollout history deploy/webapp
k rollout undo deploy/webapp # Rollback
```

## Pulizia
```bash
minikube delete # O cancella solo: k delete ns ckad-webapp
```

## Note CKAD
- Tempo stimato: 15-20 min.
- Focus: probes evitano pod "pending", risorse prevengono OOM.
- Pro tip: `k run tmp --image=busybox --rm -it -- wget -O- webapp:80` per test interno.