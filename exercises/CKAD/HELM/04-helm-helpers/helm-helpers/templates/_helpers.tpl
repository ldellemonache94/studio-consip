{{/*
Genera il fullname della release: <release-name>-<chart-name>
Troncato a 63 caratteri (limite K8s) e senza trattino finale.
*/}}
{{- define "helm-helpers.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Label standard Kubernetes applicate a TUTTE le risorse.
Includono sia le selectorLabels che info aggiuntive (versione, chart).
*/}}
{{- define "helm-helpers.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{ include "helm-helpers.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Label usate nel selector del Deployment e nei matchLabels dei Pod.
Separate da "labels" perché il selector è IMMUTABILE dopo il primo deploy:
non puoi aggiornarlo senza cancellare il Deployment.
Quindi contiene solo label stabili che non cambiano mai.
*/}}
{{- define "helm-helpers.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
