***
```markdown
# Helm – Anatomia dei Template: capire ogni riga

> 📚 Riferimento ufficiale: [helm.sh/docs/chart_template_guide](https://helm.sh/docs/chart_template_guide/)  
> Questo file spiega **perché** e **come** funziona ogni parte di un template Helm,
> riga per riga.

---

## Perché si usano le `{{ }}`?

Helm usa il motore di template **Go templates**, il linguaggio di templating
del linguaggio Go. Le doppie graffe `{{ }}` sono il segnale al motore Helm:

> "Questo non è YAML statico. Qui c'è un'espressione da valutare e sostituire."

Tutto ciò che è **fuori** da `{{ }}` viene copiato letteralmente nel manifest finale.
Tutto ciò che è **dentro** viene elaborato dinamicamente prima di essere inviato a kubectl.

### Flusso di elaborazione
```
values.yaml  ─┐
               ├──► Motore Go Template ──► YAML finale ──► kubectl apply
templates/   ─┘
--set flags  ─┘
```

---

## Varianti delle doppie graffe

| Sintassi   | Significato                                                          |
|------------|----------------------------------------------------------------------|
| `{{ }}`    | Espressione standard: valuta e inserisce il risultato                |
| `{{- }}`   | Rimuove **tutti gli spazi/newline a sinistra** prima del tag         |
| `{{ -}}`   | Rimuove **tutti gli spazi/newline a destra** dopo il tag             |
| `{{- -}}`  | Rimuove spazi sia a sinistra che a destra                            |
| `{{/* */}}`| Commento: ignorato completamente nel rendering                       |

### Esempio pratico whitespace
```yaml
# SENZA trattino: lascia righe vuote indesiderate
spec:
  {{ if .Values.enabled }}
  replicas: 3
  {{ end }}

# CON trattino: YAML pulito, nessuna riga vuota
spec:
  {{- if .Values.enabled }}
  replicas: 3
  {{- end }}
```
> ⚠️ La gestione degli spazi è uno degli errori più comuni nei template Helm.
> Usa sempre `{{-` per blocchi `if`, `range`, `end`, `define`.

---

## Gli Oggetti Built-in

Dentro `{{ }}` puoi accedere a oggetti predefiniti da Helm.
Il **punto** `.` rappresenta il contesto corrente (scope).

### `.Values` – I tuoi valori da values.yaml
```yaml
# values.yaml
replicaCount: 3
image:
  repository: nginx
  tag: "1.25"
```
```yaml
# template
replicas: {{ .Values.replicaCount }}          # → 3
image: {{ .Values.image.repository }}:{{ .Values.image.tag }}  # → nginx:1.25
```

### `.Release` – Info sulla release corrente
```yaml
{{ .Release.Name }}        # Nome dato a helm install (es. "my-app")
{{ .Release.Namespace }}   # Namespace di deploy
{{ .Release.Service }}     # Sempre "Helm"
{{ .Release.Revision }}    # Numero revisione (1, 2, 3...)
{{ .Release.IsInstall }}   # true se è la prima install
{{ .Release.IsUpgrade }}   # true se è un upgrade
```

### `.Chart` – Dati da Chart.yaml
```yaml
{{ .Chart.Name }}          # nome del chart
{{ .Chart.Version }}       # versione del chart (es. "0.1.0")
{{ .Chart.AppVersion }}    # versione dell'app (es. "1.25")
{{ .Chart.Description }}   # descrizione
```

### `.Capabilities` – Info sul cluster
```yaml
{{ .Capabilities.KubeVersion.Major }}   # Versione major K8s (es. "1")
{{ .Capabilities.KubeVersion.Minor }}   # Versione minor K8s (es. "28")
```

### `.Template` – Info sul file corrente
```yaml
{{ .Template.Name }}       # Percorso del file template corrente
```

---

## Anatomy completa – deployment.yaml riga per riga

```yaml
# ── Riga 1: YAML standard Kubernetes ──────────────────────────────────────────
apiVersion: apps/v1
kind: Deployment

metadata:
  # .Release.Name = nome passato a "helm install <nome>"
  # Es: helm install my-app → name: my-app
  name: {{ .Release.Name }}

  # .Release.Namespace = namespace passato con --namespace
  namespace: {{ .Release.Namespace }}

  labels:
    # include "nome-template" . → richiama un named template da _helpers.tpl
    # Il punto finale "." passa il contesto corrente al template
    # nindent 4 → aggiunge newline + 4 spazi di indentazione (mantiene YAML valido)
    {{- include "my-app.labels" . | nindent 4 }}

spec:
  # .Values.replicaCount legge il campo replicaCount da values.yaml
  replicas: {{ .Values.replicaCount }}

  selector:
    matchLabels:
      # Usa .Release.Name come label selector per collegare Deploy → Pod
      app: {{ .Release.Name }}

  template:
    metadata:
      labels:
        app: {{ .Release.Name }}

    spec:
      containers:
      - name: webapp

        # printf formatta una stringa: "nginx:1.25-alpine"
        # Equivale a: {{ .Values.image.repository }}:{{ .Values.image.tag }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"

        # .Values.image.pullPolicy → di solito "IfNotPresent" o "Always"
        imagePullPolicy: {{ .Values.image.pullPolicy }}

        ports:
        - containerPort: {{ .Values.service.targetPort }}

        env:
        - name: MESSAGE
          valueFrom:
            configMapKeyRef:
              # Il nome del ConfigMap deve corrispondere a quello creato nel template configmap.yaml
              name: {{ .Release.Name }}-config
              key: APP_MESSAGE

        - name: SECRET_PASS
          valueFrom:
            secretKeyRef:
              name: {{ .Release.Name }}-secret
              key: APP_PASSWORD

        resources:
          requests:
            # | quote aggiunge virgolette: "64Mi" invece di 64Mi
            # Necessario perché YAML potrebbe interpretare certi valori come numeri
            memory: {{ .Values.resources.requests.memory | quote }}
            cpu: {{ .Values.resources.requests.cpu | quote }}
          limits:
            memory: {{ .Values.resources.limits.memory | quote }}
            cpu: {{ .Values.resources.limits.cpu | quote }}

        livenessProbe:
          httpGet:
            path: {{ .Values.probes.liveness.path }}
            port: {{ .Values.service.targetPort }}
          # Legge i secondi da values.yaml, non hardcoded
          initialDelaySeconds: {{ .Values.probes.liveness.initialDelaySeconds }}
          periodSeconds: {{ .Values.probes.liveness.periodSeconds }}

        readinessProbe:
          httpGet:
            path: {{ .Values.probes.readiness.path }}
            port: {{ .Values.service.targetPort }}
          initialDelaySeconds: {{ .Values.probes.readiness.initialDelaySeconds }}
          periodSeconds: {{ .Values.probes.readiness.periodSeconds }}
```

---

## Anatomy completa – secret.yaml riga per riga

```yaml
apiVersion: v1
kind: Secret
metadata:
  # Release.Name garantisce nome univoco per release
  name: {{ .Release.Name }}-secret
  namespace: {{ .Release.Namespace }}
type: Opaque
data:
  # b64enc → codifica automaticamente in Base64 (obbligatorio per i Secret K8s)
  # quote → aggiunge virgolette alla stringa codificata
  # Pipeline: prende il valore → lo codifica → aggiunge virgolette
  APP_PASSWORD: {{ .Values.secret.appPassword | b64enc | quote }}
```

---

## Anatomy completa – configmap.yaml riga per riga

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-config
  namespace: {{ .Release.Namespace }}
data:
  # quote aggiunge virgolette al valore: necessario se la stringa contiene
  # caratteri speciali YAML come ":" o "#"
  APP_MESSAGE: {{ .Values.config.appMessage | quote }}
```

---

## Anatomy completa – _helpers.tpl riga per riga

```yaml
{{/*
Questo è un commento Helm: non viene renderizzato nel manifest finale.
Usalo per documentare il named template.
*/}}

{{/*
"define" apre la definizione di un named template riutilizzabile.
Il nome segue la convenzione: "<nome-chart>.<funzione>"
I trattini {{- e -}} rimuovono gli spazi/newline attorno al blocco.
*/}}
{{- define "my-app.labels" -}}

{{/*
Queste sono le label standard Kubernetes raccomandate (app.kubernetes.io/*)
Rendono le risorse identificabili da tool come Lens, kubectl, Helm stesso.
*/}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}

{{/*
| quote assicura che la versione sia sempre una stringa (es. "1.25" non 1.25)
*/}}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}

{{/*
printf formatta una stringa combinando nome e versione del chart
*/}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}

{{/*
"end" chiude il blocco define
*/}}
{{- end }}


{{/*
Secondo named template: genera il fullname della release
trunc 63 → K8s impone max 63 caratteri nei nomi
trimSuffix "-" → rimuove eventuale trattino finale
*/}}
{{- define "my-app.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
```

---

## Pipeline `|` – Come funziona

La pipeline `|` passa il risultato di un'espressione alla funzione successiva,
esattamente come la pipe di Linux (`|`).

```yaml
# Senza pipeline (meno leggibile)
{{ b64enc (quote .Values.secret.password) }}

# Con pipeline (stile Helm raccomandato)
{{ .Values.secret.password | b64enc | quote }}

# Esempio complesso: nome troncato, senza trattino finale, tra virgolette
{{ printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" | quote }}
```

---

## Condizionali – if/else/end

```yaml
spec:
  {{- if .Values.autoscaling.enabled }}
  # Questo blocco viene renderizzato SOLO se autoscaling.enabled = true
  # Il trattino {{- rimuove la riga vuota che if lascerebbe
  replicas: 1   # HPA gestirà le repliche
  {{- else }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
```

### Operatori logici
```yaml
{{- if and .Values.ingress.enabled .Values.ingress.tls }}
# Renderizzato solo se ENTRAMBI i valori sono true
{{- end }}

{{- if or .Values.debug .Values.verbose }}
# Renderizzato se almeno uno è true
{{- end }}

{{- if not .Values.autoscaling.enabled }}
# Renderizzato se il valore è false/nil
{{- end }}
```

---

## `with` – Cambia il contesto `.`

`with` sposta il punto `.` dentro il blocco, evitando path lunghi:

```yaml
# Senza with: ripeti .Values.resources ogni volta
resources:
  requests:
    memory: {{ .Values.resources.requests.memory }}
    cpu: {{ .Values.resources.requests.cpu }}
  limits:
    memory: {{ .Values.resources.limits.memory }}
    cpu: {{ .Values.resources.limits.cpu }}

# Con with: . diventa .Values.resources dentro il blocco
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

> ⚠️ `with` non entra nel blocco se il valore è nil/empty: utile come guardia.

---

## `range` – Itera su liste e mappe

### Lista
```yaml
# values.yaml
ports:
  - 8080
  - 8443
  - 9090
```
```yaml
# template
ports:
  {{- range .Values.ports }}
  - containerPort: {{ . }}   # Il punto "." rappresenta l'elemento corrente
  {{- end }}
```

### Lista di oggetti
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

### Mappa (key/value)
```yaml
# values.yaml
annotations:
  team: devops
  project: ckad
```
```yaml
# template
annotations:
  {{- range $key, $value := .Values.annotations }}
  {{ $key }}: {{ $value | quote }}
  {{- end }}
```

---

## `include` vs `template`

Helm offre due modi per richiamare named template:

| Sintassi                        | Differenza                                              |
|---------------------------------|---------------------------------------------------------|
| `{{ include "nome" . }}`        | ✅ Restituisce stringa → pipeable con `\| nindent 4`    |
| `{{ template "nome" . }}`       | ❌ Non pipeable, non supporta indentazione dinamica     |

**Usa sempre `include`:**
```yaml
labels:
  {{- include "my-app.labels" . | nindent 4 }}
```

---

## Errori Comuni e Soluzioni

| Errore                              | Causa                                      | Soluzione                              |
|-------------------------------------|--------------------------------------------|----------------------------------------|
| YAML invalido (indentazione errata) | Manca `nindent` dopo `include`             | Aggiungi `\| nindent N`                |
| Righe vuote inaspettate             | Manca `{{-` nei blocchi if/range/end       | Aggiungi trattino sinistro             |
| `<nil>` nel manifest                | Valore non definito in values.yaml         | Aggiungi `\| default "valore"`         |
| Nome risorsa troppo lungo           | Release name + chart name > 63 char       | Usa `\| trunc 63 \| trimSuffix "-"`    |
| Secret in chiaro nel manifest       | Dimenticato `\| b64enc`                    | Aggiungi `\| b64enc \| quote`          |

---

## Cheat Sheet Template

```yaml
# Valore da values.yaml
{{ .Values.chiave }}

# Valore con default se assente
{{ .Values.chiave | default "fallback" }}

# Stringa con virgolette
{{ .Values.chiave | quote }}

# Base64 (per Secret)
{{ .Values.chiave | b64enc | quote }}

# Nome troncato a 63 char
{{ printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}

# Include named template con indentazione
{{- include "my-app.labels" . | nindent 4 }}

# Condizionale
{{- if .Values.enabled }} ... {{- end }}

# Iterazione lista
{{- range .Values.lista }} {{ . }} {{- end }}

# Iterazione mappa
{{- range $k, $v := .Values.mappa }} {{ $k }}: {{ $v }} {{- end }}

# Cambia scope
{{- with .Values.blocco }} {{ .campo }} {{- end }}

# Commento (non renderizzato)
{{/* Questo è un commento */}}
```

---

## Link Utili

| Risorsa                          | URL                                                                     |
|----------------------------------|-------------------------------------------------------------------------|
| Guida ufficiale ai template      | https://helm.sh/docs/chart_template_guide/                              |
| Go template sintassi base        | https://helm.sh/docs/chart_template_guide/getting_started/              |
| Funzioni built-in + Sprig        | https://helm.sh/docs/chart_template_guide/function_list/                |
| Flow control (if/range/with)     | https://helm.sh/docs/chart_template_guide/control_structures/           |
| Named templates (_helpers.tpl)   | https://helm.sh/docs/chart_template_guide/named_templates/              |
| Gestione whitespace              | https://helm.sh/docs/chart_template_guide/control_structures/#whitespace|
```
***