```markdown
# Guida completa a Helm per Kubernetes

> 📚 Documentazione ufficiale: [helm.sh/docs](https://helm.sh/docs/)  
> 🔧 GitHub: [github.com/helm/helm](https://github.com/helm/helm)  
> 🌐 Artifact Hub (cerca chart pubblici): [artifacthub.io](https://artifacthub.io)

---

## Cos'è Helm?

Helm è il **package manager ufficiale per Kubernetes**.  
Semplifica il deploy di applicazioni complesse su un cluster K8s, esattamente come:

- `apt` / `yum` fanno con i pacchetti Linux
- `npm` fa con i pacchetti Node.js

Invece di applicare decine di manifest YAML separati con `kubectl apply`,
con Helm impacchetti tutto in un **Chart** e lo gestisci con un singolo comando.

📖 [Introduzione ufficiale](https://helm.sh/docs/intro/)

---

## Concetti Chiave

| Termine       | Descrizione                                                                 |
|---------------|-----------------------------------------------------------------------------|
| **Chart**     | Pacchetto Helm: raccolta di template YAML + valori di default               |
| **Release**   | Istanza di un chart installata nel cluster (ogni `helm install` = 1 release)|
| **Revision**  | Versione della release: aumenta a ogni `upgrade` o `rollback`               |
| **values.yaml** | File dei parametri configurabili del chart                                |
| **Template**  | Manifest YAML con variabili Go template: `{{ .Values.xxx }}`                |
| **Repository**| Server HTTP che ospita chart impacchettati (es. Bitnami, Artifact Hub)      |

📖 [Glossario ufficiale](https://helm.sh/docs/glossary/)

---

## Installazione

### Su WSL / Linux
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
# Output atteso: version.BuildInfo{Version:"v3.x.x", ...}
```

### Verifica
```bash
helm env       # Mostra variabili d'ambiente Helm (HELM_CACHE_HOME, ecc.)
helm help      # Lista comandi disponibili
```

📖 [Guida all'installazione](https://helm.sh/docs/intro/install/)

---

## Struttura di un Chart

```
my-chart/
├── Chart.yaml          # Metadati del chart (nome, versione, descrizione)
├── values.yaml         # Valori di default (parametri configurabili)
├── charts/             # Dipendenze (sub-chart)
└── templates/          # Manifest YAML con variabili Go template
    ├── deployment.yaml
    ├── service.yaml
    ├── configmap.yaml
    └── NOTES.txt       # Messaggio mostrato dopo install (opzionale)
```

📖 [Struttura chart ufficiale](https://helm.sh/docs/topics/charts/)

### Chart.yaml – esempio
```yaml
apiVersion: v2
name: my-app
description: La mia applicazione Kubernetes
type: application
version: 0.1.0       # Versione del chart stesso
appVersion: "1.25"   # Versione dell'app deployata
```

### values.yaml – esempio
```yaml
replicaCount: 3

image:
  repository: nginx
  tag: "1.25-alpine"

service:
  port: 80
  type: ClusterIP

config:
  message: "Hello from Helm!"
```

---

## Go Template – Sintassi Base

I file in `templates/` usano la **Go template syntax** per inserire valori dinamici.

| Sintassi                          | Significato                                    |
|-----------------------------------|------------------------------------------------|
| `{{ .Values.replicaCount }}`      | Legge un valore da `values.yaml`               |
| `{{ .Release.Name }}`             | Nome della release (passato a `helm install`)  |
| `{{ .Release.Namespace }}`        | Namespace della release                        |
| `{{ .Chart.Version }}`            | Versione del chart da `Chart.yaml`             |
| `{{ "testo" \| quote }}`          | Aggiunge virgolette a una stringa              |
| `{{ "pass" \| b64enc }}`          | Codifica in Base64 (utile per Secret)          |

📖 [Guida ai template](https://helm.sh/docs/chart_template_guide/)

### Esempio pratico – deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}
    spec:
      containers:
      - name: app
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
```

---

## Comandi Principali

📖 [Riferimento CLI completo](https://helm.sh/docs/helm/)

### Gestione Repository
```bash
# Aggiunge un repository
helm repo add bitnami https://charts.bitnami.com/bitnami

# Lista repository aggiunti
helm repo list

# Aggiorna la cache locale dei chart
helm repo update

# Cerca un chart su un repo
helm search repo bitnami/nginx
```

### Installazione e Gestione Release
```bash
# Installa un chart (crea una release)
helm install <release-name> <chart>

# Esempio: installa il chart locale ./my-chart
helm install my-app ./my-chart --namespace my-ns --create-namespace

# Override di un singolo valore
helm install my-app ./my-chart --set replicaCount=5

# Override tramite file di valori custom
helm install my-app ./my-chart -f values-prod.yaml

# Lista release installate nel namespace corrente
helm list -n my-ns

# Lista release in tutti i namespace
helm list -A
```

### Upgrade e Rollback
```bash
# Aggiorna una release esistente (revision +1)
helm upgrade my-app ./my-chart --namespace my-ns

# Upgrade + override al volo
helm upgrade my-app ./my-chart --set image.tag="1.26-alpine"

# Upgrade + override da file
helm upgrade my-app ./my-chart -f values-prod.yaml

# Installa se non esiste, aggiorna se esiste (utile in CI/CD)
helm upgrade --install my-app ./my-chart --namespace my-ns --create-namespace

# Vedi la storia delle revision
helm history my-app -n my-ns

# Rollback alla revision 1
helm rollback my-app 1 -n my-ns
```

### Ispezione e Debug
```bash
# Renderizza i template SENZA toccare il cluster (dry-run locale)
helm template my-app ./my-chart

# Simula install con validazione server-side
helm install my-app ./my-chart --dry-run --debug

# Mostra i values attivi su una release installata
helm get values my-app -n my-ns

# Mostra i manifest YAML generati per una release
helm get manifest my-app -n my-ns

# Status della release
helm status my-app -n my-ns
```

### Rimozione
```bash
# Rimuove la release dal cluster
helm uninstall my-app -n my-ns
```

---

## Precedenza dei Values

Helm applica i valori in quest'ordine (dal meno al più prioritario):

```
values.yaml (default)
    ↓
-f custom-values.yaml
    ↓
--set chiave=valore    ← vince su tutto
```

📖 [Gestione dei values](https://helm.sh/docs/chart_template_guide/values_files/)

### Esempio pratico
```bash
# values.yaml ha replicaCount: 3
# custom.yaml ha replicaCount: 2
# --set imposta replicaCount=5

helm install my-app ./my-chart \
  -f custom.yaml \
  --set replicaCount=5
# Risultato finale: replicaCount = 5
```

---

## Dipendenze tra Chart

Un chart può dipendere da altri chart (es. la tua app dipende da PostgreSQL).
Le dipendenze si dichiarano in `Chart.yaml`:

```yaml
dependencies:
  - name: postgresql
    version: "12.x.x"
    repository: "https://charts.bitnami.com/bitnami"
```

Poi si scaricano con:
```bash
helm dependency update ./my-chart
# Genera charts/postgresql-12.x.x.tgz nella cartella charts/
```

📖 [Dipendenze ufficiali](https://helm.sh/docs/helm/helm_dependency/)

---

## Flusso Completo – Esempio End-to-End

```bash
# 1. Crea un nuovo chart da zero
helm create my-app

# 2. Modifica templates/ e values.yaml a piacere

# 3. Valida il rendering dei template
helm template my-app ./my-app

# 4. Test dry-run con validazione cluster
helm install my-app ./my-app --dry-run --debug --namespace dev

# 5. Deploy reale
helm install my-app ./my-app --namespace dev --create-namespace

# 6. Verifica
helm list -n dev
kubectl get all -n dev

# 7. Upgrade con nuovi valori
helm upgrade my-app ./my-app --set replicaCount=5 --namespace dev

# 8. Verifica history
helm history my-app -n dev

# 9. Rollback
helm rollback my-app 1 -n dev

# 10. Pulizia
helm uninstall my-app -n dev
kubectl delete ns dev
```

---

## Cheat Sheet Rapida

| Azione                        | Comando                                             |
|-------------------------------|-----------------------------------------------------|
| Installa chart                | `helm install <rel> <chart> -n <ns>`                |
| Aggiorna release              | `helm upgrade <rel> <chart> -n <ns>`                |
| Install o upgrade (idempotente)| `helm upgrade --install <rel> <chart> -n <ns>`     |
| Lista release                 | `helm list -n <ns>`                                 |
| Storia revision               | `helm history <rel> -n <ns>`                        |
| Rollback                      | `helm rollback <rel> <revision> -n <ns>`            |
| Values attivi                 | `helm get values <rel> -n <ns>`                     |
| Manifest generati             | `helm get manifest <rel> -n <ns>`                   |
| Render locale (no cluster)    | `helm template <rel> <chart>`                       |
| Dry run + debug               | `helm install <rel> <chart> --dry-run --debug`      |
| Rimuovi release               | `helm uninstall <rel> -n <ns>`                      |

📖 [Cheat sheet ufficiale](https://helm.sh/docs/intro/cheatsheet/)

---

## Link Utili

| Risorsa                        | URL                                                        |
|--------------------------------|------------------------------------------------------------|
| Documentazione ufficiale       | https://helm.sh/docs/                                      |
| Guida ai template              | https://helm.sh/docs/chart_template_guide/                 |
| Riferimento comandi CLI        | https://helm.sh/docs/helm/                                 |
| Best practices ufficiali       | https://helm.sh/docs/chart_best_practices/                 |
| Artifact Hub (chart pubblici)  | https://artifacthub.io                                     |
| GitHub Helm                    | https://github.com/helm/helm                               |
```
