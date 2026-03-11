# Esercizio CKAD 3: Deploy con Helm

## Obiettivo
Imparare a creare, installare e gestire un Helm chart da zero.
Helm è il package manager di Kubernetes: permette di parametrizzare
i manifest YAML tramite variabili (values.yaml), versionare i deploy
e fare rollback facilmente.

In questo esercizio riprendiamo la webapp dell'Esercizio 1,
ma la deployamo tramite Helm invece di kubectl apply.

## Prerequisiti
- WSL + Minikube avviato (`minikube status`)
- kubectl installato e configurato
- Helm NON installato? Installalo così:

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts get-helm-3 | bash
helm version  # Verifica: version.BuildInfo{Version:"v3.x.x"}
```

Concetti base Helm (leggi prima di iniziare)
Termine-Significato
Chart-"Pacchetto" Helm: contiene template YAML + valori di default
Release-Un'installazione di un chart nel cluster
values.yaml-File dei parametri configurabili del chart
Template-Manifest YAML con variabili {{ .Values.xxx }}
Revision-Versione della release (aumenta a ogni upgrade/rollback)

# Step 1 – Esplora il chart
Prima di installare, ispeziona la struttura:

```bash
cd 03-helm/
ls helm-webapp/          # Chart.yaml, values.yaml, templates/
cat helm-webapp/Chart.yaml
cat helm-webapp/values.yaml   # Qui ci sono tutti i parametri
```

Renderizza i template senza installare (ottimo per debug):

```bash
helm template my-webapp ./helm-webapp
```
Dovresti vedere i YAML finali con le variabili sostituite dai valori in values.yaml.

# Step 2 – Crea il namespace

```bash
kubectl create ns ckad-helm
```

# Step 3 – Installa il chart

```bash
helm install my-webapp ./helm-webapp \
  --namespace ckad-helm \
  --create-namespace
```

## Verifica l'installazione:

```bash
helm list -n ckad-helm           # Mostra release, status, revision
kubectl get all -n ckad-helm     # Pod, Deploy, Service
kubectl describe pod -n ckad-helm  # Controlla probes e env vars
```

# Step 4 – Test applicazione

```bash
kubectl port-forward svc/helm-webapp 8080:80 -n ckad-helm
# In un altro terminale WSL:
curl localhost:8080
```

# Step 5 – Upgrade con override di values

Modifica il numero di repliche e il messaggio SENZA toccare i YAML:

```bash
helm upgrade my-webapp ./helm-webapp \
  --namespace ckad-helm \
  --set replicaCount=5 \
  --set config.appMessage="Upgraded via Helm!"
```

Verifica:

```bash
helm list -n ckad-helm          # Revision deve essere 2
kubectl get pods -n ckad-helm   # Ora ci sono 5 pod
```

# Step 6 – Rollback

```bash
helm rollback my-webapp 1 -n ckad-helm   # Torna alla revision 1
helm list -n ckad-helm                   # Revision 3 (rollback conta come nuova revision)
kubectl get pods -n ckad-helm            # Torna a 3 repliche
```

# Step 7 – Helm History
```bash
helm history my-webapp -n ckad-helm
```
Output atteso:

REVISION  STATUS      DESCRIPTION
1         superseded  Install complete
2         superseded  Upgrade complete
3         deployed    Rollback to 1

# Step 8 – Override tramite file (stile CI/CD)
Crea un file values-prod.yaml personalizzato:
```yaml
replicaCount: 2
config:
  appMessage: "Produzione!"
secret:
  appPassword: "supersecret"
image:
  tag: "1.26-alpine"
```
Applica:
```bash
helm upgrade my-webapp ./helm-webapp \
  --namespace ckad-helm \
  -f values-prod.yaml
```

# Step 9 – Pulizia
```bash
helm uninstall my-webapp -n ckad-helm
kubectl delete ns ckad-helm
```
Domande di verifica:
Qual è la differenza tra helm install e helm upgrade?
Come si vedono tutte le release installate in un namespace?
Cosa succede alla revision number dopo un rollback?
Come si testano i template senza toccare il cluster?
Cosa cambia tra usare --set e -f values.yaml?