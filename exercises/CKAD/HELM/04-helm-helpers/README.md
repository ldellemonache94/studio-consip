# Esercizio CKAD 4 – Helm _helpers.tpl e Named Templates

## Obiettivo
Capire come funzionano i named template in `_helpers.tpl` e perché
evitano la duplicazione di label, nomi e annotazioni in tutti i file.

**Difficoltà:** ⭐⭐ (base-intermedio)  
**Tempo stimato:** 20 min  
**Prerequisiti:** Esercizio 3 completato

---

## Concetto chiave
Senza `_helpers.tpl` ogni template ripete le stesse label:
```yaml
# deployment.yaml
labels:
  app: my-app
  version: "1.0"

# service.yaml
labels:
  app: my-app       # duplicato!
  version: "1.0"    # duplicato!

# Step 1 – Analizza _helpers.tpl
```bash
cat helm-helpers/templates/_helpers.tpl
```

Individua i tre named template definiti:
helm-helpers.fullname → genera il nome completo della risorsa
helm-helpers.labels → label standard Kubernetes
helm-helpers.selectorLabels → label usate solo nel selector
Domanda: perché selectorLabels è separato da labels?

Step 2 – Renderizza e osserva

```bash
helm template my-release ./helm-helpers
```

Cerca nel output:
Dove appaiono le label generate da helm-helpers.labels
Come cambia il nome della risorsa al variare di --set sul release name

# Step 3 – Installa
```bash
kubectl create ns ckad-helpers
helm install my-release ./helm-helpers --namespace ckad-helpers
kubectl get all -n ckad-helpers
kubectl get deploy my-release-helm-helpers -n ckad-helpers -o yaml | grep -A 10 labels
```
# Step 4 – Modifica l'helper (esercizio scritto)
Apri _helpers.tpl e aggiungi un nuovo named template chiamato
helm-helpers.annotations che genera:

```yaml
annotations:
  managed-by: helm
  team: {{ .Values.team }}
```

Poi usalo in deployment.yaml con include e nindent 8.
Verifica con helm template che le annotazioni appaiano correttamente.

# Step 5 – Verifica e pulizia
```bash
helm template my-release ./helm-helpers  # controlla annotazioni
helm uninstall my-release -n ckad-helpers
kubectl delete ns ckad-helpers
```

Domande di verifica
Perché il file si chiama _helpers.tpl con underscore?
Qual è la differenza tra include e template?
Cosa fa | nindent 4 e perché è necessario?
Cosa succede se chiami include su un template non definito?

***