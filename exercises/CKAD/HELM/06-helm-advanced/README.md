# Esercizio CKAD 6 – Chart Avanzato: Schema, Test e CI/CD Pattern

## Obiettivo
Costruire un chart production-grade con:
- Validazione dei values tramite JSON Schema
- Test automatici con `helm test`
- Pattern `upgrade --install` per CI/CD idempotente
- `helm get` e `helm history` per audit completo

**Difficoltà:** ⭐⭐⭐⭐⭐ (avanzato)  
**Tempo stimato:** 35-40 min  
**Prerequisiti:** Esercizi 4 e 5 completati

---

## Step 1 – Valida lo schema prima di installare
```bash
# Prova a passare un valore non valido: deve fallire con errore chiaro
helm install test-schema ./helm-advanced \
  --namespace ckad-adv \
  --set replicaCount=abc
```
# Error: values don't meet the specifications of the schema(s)

# Prova a passare un tag immagine numerico invece di stringa
```bash
helm install test-schema ./helm-advanced \
  --namespace ckad-adv \
  --set image.tag=125
  ```
# Error: image.tag must be a string
# Step 2 – Dry run completo (simula senza toccare il cluster)
```bash
helm install my-adv ./helm-advanced \
  --namespace ckad-adv \
  --create-namespace \
  --dry-run --debug
```

Osserva: manifest renderizzati, NOTES.txt, computed values.

# Step 3 – Installa
```bash
kubectl create ns ckad-adv
helm install my-adv ./helm-advanced --namespace ckad-adv
helm status my-adv -n ckad-adv   # Leggi il NOTES.txt mostrato
kubectl get all -n ckad-adv
```
# Step 4 – Esegui i test automatici
```bash
helm test my-adv -n ckad-adv
# Pod my-adv-test-connection: Succeeded
kubectl get pods -n ckad-adv    # Vedi il pod di test (completato)
kubectl logs my-adv-helm-advanced-test -n ckad-adv  # Output del test
```

# Step 5 – Pattern CI/CD: upgrade --install
```bash
# Simula una pipeline CI: idempotente, funziona sia al primo deploy che agli upgrade
helm upgrade --install my-adv ./helm-advanced \
  --namespace ckad-adv \
  --create-namespace \
  --set image.tag="1.26-alpine" \
  --wait \
  --timeout 3m

helm history my-adv -n ckad-adv  # Revision 2
```
# Step 6 – Audit completo della release
```bash
# Values attualmente attivi (quelli passati con --set o -f)
helm get values my-adv -n ckad-adv

# Tutti i values inclusi i default di values.yaml
helm get values my-adv -n ckad-adv --all

# Manifest YAML che Helm ha applicato al cluster
helm get manifest my-adv -n ckad-adv

# History completa con status di ogni revision
helm history my-adv -n ckad-adv
```
# Step 7 – Rollback e verifica
```bash
helm rollback my-adv 1 -n ckad-adv   # Torna a image.tag 1.25-alpine
helm history my-adv -n ckad-adv       # Revision 3 (rollback = nuova revision)
helm get values my-adv -n ckad-adv    # Verifica che tag sia tornato 1.25-alpine
```

# Step 8 – Lint del chart
```bash
helm lint ./helm-advanced
# Deve passare senza errori
```

# Step 9 – Pulizia
```bash
helm uninstall my-adv -n ckad-adv
kubectl delete ns ckad-adv
```

Domande di verifica
Cosa succede se non metti --wait in una pipeline CI?
Qual è la differenza tra helm get values e helm get values --all?
A cosa serve il JSON Schema in produzione?
Perché dopo un rollback la revision number aumenta invece di diminuire?
Come verificheresti da CI che il helm test è passato?