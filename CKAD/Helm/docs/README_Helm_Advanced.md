***

```markdown
# Helm – Funzionalità Avanzate

> 📚 Documentazione ufficiale: [helm.sh/docs](https://helm.sh/docs/)
> Questo file è il naturale seguito di `HELM.md`: presuppone che tu conosca già
> i concetti base (Chart, Release, values.yaml, template).

---

## `helm create` – Scaffold Automatico

Invece di creare la struttura di un chart a mano, Helm la genera per te:

```bash
helm create my-app
```

Genera automaticamente:
```
my-app/
├── Chart.yaml
├── values.yaml
├── charts/
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    ├── serviceaccount.yaml
    ├── ingress.yaml
    ├── hpa.yaml
    ├── _helpers.tpl     <- File helper (vedi sezione sotto)
    └── NOTES.txt        <- Messaggio post-install
```

> 💡 Pro tip: usa `helm create` come punto di partenza e poi
> elimina i template che non ti servono. È più veloce che partire da zero.

📖 [helm create – docs ufficiali](https://helm.sh/docs/helm/helm_create/)

---

## `_helpers.tpl` – Template Riutilizzabili

Il file `templates/_helpers.tpl` (il `_` fa sì che Helm non lo tratti come
manifest K8s) contiene **named template** riutilizzabili in tutti gli altri file.

### Definizione
```yaml
{{/*
Genera il nome completo della release
*/}}
{{- define "my-app.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Labels comuni da applicare a tutte le risorse
*/}}
{{- define "my-app.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end }}
```

### Utilizzo nei template
```yaml
metadata:
  name: {{ include "my-app.fullname" . }}
  labels:
    {{- include "my-app.labels" . | nindent 4 }}
```

> `nindent 4` aggiunge automaticamente 4 spazi di indentazione a ogni riga:
> essenziale per mantenere il YAML valido.

📖 [Named templates ufficiali](https://helm.sh/docs/chart_template_guide/named_templates/)

---

## `NOTES.txt` – Messaggio Post-Install

Il file `templates/NOTES.txt` viene mostrato all'utente dopo ogni
`helm install` o `helm upgrade`. Supporta variabili Go template.

### Esempio
```
🚀 Release {{ .Release.Name }} installata con successo!

Accedi all'applicazione:
  kubectl port-forward svc/{{ .Release.Name }} 8080:{{ .Values.service.port }} -n {{ .Release.Namespace }}
  curl localhost:8080

Per vedere i log:
  kubectl logs deploy/{{ .Release.Name }} -n {{ .Release.Namespace }} -f

Per fare upgrade:
  helm upgrade {{ .Release.Name }} ./{{ .Chart.Name }} --namespace {{ .Release.Namespace }}
```

> 💡 Un buon NOTES.txt è molto apprezzato in team e nei chart pubblici:
> evita di dover consultare il README per i comandi base post-deploy.

📖 [NOTES.txt – docs ufficiali](https://helm.sh/docs/chart_template_guide/notes_files/)

---

## Funzioni Template Utili

Helm include la libreria **Sprig** con decine di funzioni utilizzabili nei template.

📖 [Funzioni template complete](https://helm.sh/docs/chart_template_guide/function_list/)

### Stringhe
```yaml
# Aggiunge virgolette
{{ .Values.config.message | quote }}           # "Hello!"

# Tronca a N caratteri
{{ .Release.Name | trunc 63 }}

# Converte in uppercase/lowercase
{{ .Values.env | upper }}                      # PRODUCTION
{{ .Values.env | lower }}                      # production

# Sostituisce caratteri
{{ .Release.Name | replace "-" "_" }}
```

### Valori di Default
```yaml
# Se replicaCount non è definito in values.yaml, usa 1
{{ .Values.replicaCount | default 1 }}

# Se il tag è vuoto, usa "latest"
{{ .Values.image.tag | default "latest" | quote }}
```

### Codifica
```yaml
# Base64 encode (usato nei Secret)
{{ .Values.secret.password | b64enc | quote }}

# Base64 decode
{{ .Values.secret.encoded | b64dec }}
```

### Indentazione
```yaml
# nindent: aggiunge newline + N spazi
labels:
  {{- include "my-app.labels" . | nindent 4 }}

# indent: solo N spazi (senza newline iniziale)
  {{- include "my-app.labels" . | indent 4 }}
```

---

## Condizionali e Cicli

### if / else
```yaml
spec:
  {{- if .Values.service.nodePort }}
  type: NodePort
  {{- else }}
  type: ClusterIP
  {{- end }}
```

### range – Itera su liste
```yaml
# values.yaml
envVars:
  - name: ENV
    value: production
  - name: LOG_LEVEL
    value: info
```

```yaml
# template
env:
  {{- range .Values.envVars }}
  - name: {{ .name }}
    value: {{ .value | quote }}
  {{- end }}
```

### range – Itera su mappe
```yaml
# values.yaml
labels:
  team: devops
  project: ckad
```

```yaml
# template
labels:
  {{- range $key, $val := .Values.labels }}
  {{ $key }}: {{ $val | quote }}
  {{- end }}
```

### with – Scope su un blocco
```yaml
{{- with .Values.resources }}
resources:
  requests:
    memory: {{ .requests.memory }}
    cpu: {{ .requests.cpu }}
  limits:
    memory: {{ .limits.memory }}
    cpu: {{ .limits.cpu }}
{{- end }}
```

> `with` entra nello scope del blocco solo se il valore esiste e non è vuoto:
> evita errori se `resources` non è definito in values.yaml.

📖 [Flow control ufficiale](https://helm.sh/docs/chart_template_guide/control_structures/)

---

## Validazione dei Values con Schema JSON

Helm supporta la validazione dei `values.yaml` tramite uno schema JSON.
Crea `values.schema.json` nella root del chart:

```json
{
  "$schema": "https://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["replicaCount", "image"],
  "properties": {
    "replicaCount": {
      "type": "integer",
      "minimum": 1,
      "maximum": 10
    },
    "image": {
      "type": "object",
      "required": ["repository", "tag"],
      "properties": {
        "repository": { "type": "string" },
        "tag": { "type": "string" }
      }
    }
  }
}
```

Se un utente passa un valore non valido, Helm blocca l'install con un errore chiaro:
```bash
helm install my-app ./my-app --set replicaCount=abc
# Error: values don't meet the specifications of the schema(s) ...
```

📖 [Schema validation ufficiale](https://helm.sh/docs/topics/charts/#schema-files)

---

## Dipendenze tra Chart

Un chart può includere altri chart come dipendenze (es. la tua app + PostgreSQL).

### Dichiarazione in Chart.yaml
```yaml
dependencies:
  - name: postgresql
    version: "12.x.x"
    repository: "https://charts.bitnami.com/bitnami"
    condition: postgresql.enabled    # Installato solo se true in values.yaml
```

### Comandi
```bash
# Scarica le dipendenze in charts/
helm dependency update ./my-chart

# Lista dipendenze del chart
helm dependency list ./my-chart
```

### Abilitare/disabilitare in values.yaml
```yaml
postgresql:
  enabled: true    # Cambia a false per non installare PostgreSQL
```

📖 [Dipendenze ufficiali](https://helm.sh/docs/helm/helm_dependency/)

---

## Helm in CI/CD (Jenkins / GitLab)

Il pattern più comune in pipeline CI/CD è `upgrade --install`:
installa se la release non esiste, aggiorna se esiste. Idempotente.

### Esempio Jenkinsfile
```groovy
stage('Deploy con Helm') {
    steps {
        sh """
          helm upgrade --install my-app ./my-chart \
            --namespace production \
            --create-namespace \
            -f values-prod.yaml \
            --set image.tag=${BUILD_NUMBER} \
            --wait \
            --timeout 5m
        """
    }
}
```

### Esempio GitLab CI
```yaml
deploy:
  stage: deploy
  script:
    - helm upgrade --install my-app ./my-chart
        --namespace production
        --create-namespace
        -f values-prod.yaml
        --set image.tag=$CI_COMMIT_SHORT_SHA
        --wait
        --timeout 5m
  only:
    - main
```

> `--wait` aspetta che tutti i pod siano Ready prima di completare.
> `--timeout 5m` fallisce il deploy se supera 5 minuti (evita pipeline bloccate).

📖 [Best practices CI/CD](https://helm.sh/docs/chart_best_practices/)

---

## Lint e Test

### helm lint – Valida sintassi del chart
```bash
helm lint ./my-chart
# ==> Linting ./my-chart
# [INFO] Chart.yaml: icon is recommended
# 1 chart(s) linted, 0 chart(s) failed
```

### helm test – Esegue test definiti nel chart
I test sono Pod con annotazione `helm.sh/hook: test` che eseguono
verifiche post-deploy (es. che il service risponda):

```yaml
# templates/tests/test-connection.yaml
apiVersion: v1
kind: Pod
metadata:
  name: "{{ .Release.Name }}-test"
  annotations:
    "helm.sh/hook": test
spec:
  containers:
  - name: wget
    image: busybox
    command: ['wget', '-O-', 'http://{{ .Release.Name }}:{{ .Values.service.port }}/']
  restartPolicy: Never
```

```bash
helm test my-app -n my-ns
# Pod my-app-test: Succeeded
```

📖 [helm test ufficiale](https://helm.sh/docs/helm/helm_test/)

---

## Best Practices Rapide

- **Usa sempre `{{ .Release.Name }}` come prefisso** dei nomi delle risorse:
  evita conflitti tra release diverse nello stesso namespace.
- **Non hardcodare il namespace** nei template: usa `{{ .Release.Namespace }}`
  o lascialo fuori (viene applicato da `--namespace`).
- **Documenta ogni valore in `values.yaml`** con commenti: è la prima cosa
  che un utente legge.
- **Usa `helm lint`** sempre prima di fare push o deploy.
- **Preferisci `-f values-env.yaml`** a molti `--set` in pipeline:
  più leggibile e versionabile in Git.
- **Versiona `Chart.yaml`**: incrementa `version` ad ogni modifica del chart,
  `appVersion` ad ogni nuova versione dell'app deployata.

📖 [Best practices ufficiali](https://helm.sh/docs/chart_best_practices/)

---

## Link Utili

| Risorsa                          | URL                                                              |
|----------------------------------|------------------------------------------------------------------|
| Guida ai template                | https://helm.sh/docs/chart_template_guide/                       |
| Funzioni Sprig                   | https://helm.sh/docs/chart_template_guide/function_list/         |
| Flow control (if/range/with)     | https://helm.sh/docs/chart_template_guide/control_structures/    |
| Named templates (_helpers.tpl)   | https://helm.sh/docs/chart_template_guide/named_templates/       |
| Schema validation                | https://helm.sh/docs/topics/charts/#schema-files                 |
| Best practices ufficiali         | https://helm.sh/docs/chart_best_practices/                       |
| Artifact Hub (chart pubblici)    | https://artifacthub.io                                           |
```
***
