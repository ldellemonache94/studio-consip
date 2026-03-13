# Esercizio CKAD 5 – Condizionali, Range e With

## Obiettivo
Usare `if/else`, `range`, `with` per creare template flessibili che
generano risorse diverse in base ai values: Ingress opzionale,
HPA opzionale, env vars dinamiche da lista.

**Difficoltà:** ⭐⭐⭐ (intermedio)  
**Tempo stimato:** 25 min  
**Prerequisiti:** Esercizio 4 completato

---

## Concetto chiave
Un chart professionale non genera sempre le stesse risorse.
`if` abilita/disabilita blocchi interi, `range` itera su liste
dinamiche, `with` semplifica path lunghi.

---

## Step 1 – Esplora values.yaml
```bash
cat helm-conditionals/values.yaml
```

Nota i flag booleani: ingress.enabled, autoscaling.enabled.
Nota la lista envVars e la mappa annotations.

# Step 2 – Rendering condizionale

```bash
# Con ingress e HPA disabilitati (default)
helm template my-rel ./helm-conditionals | grep "kind:"
# Abilita ingress
helm template my-rel ./helm-conditionals --set ingress.enabled=true | grep "kind:"
# Abilita tutto
helm template my-rel ./helm-conditionals \
  --set ingress.enabled=true \
  --set autoscaling.enabled=true | grep "kind:"
```  

Osserva quante risorse cambiano al variare dei flag.

# Step 3 – Installa con configurazione base
```bash
kubectl create ns ckad-cond
helm install my-rel ./helm-conditionals --namespace ckad-cond
kubectl get all -n ckad-cond  # Solo Deploy + Service
```

# Step 4 – Upgrade con Ingress abilitato
```bash
helm upgrade my-rel ./helm-conditionals \
  --namespace ckad-cond \
  --set ingress.enabled=true \
  --set ingress.host=myapp.local

kubectl get ingress -n ckad-cond  # Ora compare l'Ingress
```

# Step 5 – Upgrade con HPA e env custom
```bash
helm upgrade my-rel ./helm-conditionals \
  --namespace ckad-cond \
  --set autoscaling.enabled=true \
  --set autoscaling.minReplicas=2 \
  --set autoscaling.maxReplicas=5

kubectl get hpa -n ckad-cond
```

# Step 6 – Pulizia
```bash
helm uninstall my-rel -n ckad-cond
kubectl delete ns ckad-cond
```
Domande di verifica
Cosa succede al Deployment se abiliti autoscaling.enabled=true?
Perché with è utile con blocchi come .Values.resources?
Come itereresti su una mappa invece che su una lista con range?
Cosa fa {{- if and .Values.ingress.enabled .Values.ingress.tls }}?

```
***