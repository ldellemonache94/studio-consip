# Esercizio 03 – Gestione di una ConfigMap Kubernetes

## Obiettivo

Lo scopo di questo esercizio è fornire le basi per:

* lavorare su **branch dedicati**;
* creare e versionare una **ConfigMap Kubernetes**;
* comprendere come gestire configurazioni applicative su Kubernetes.

---

## Regole fondamentali

* Ogni esercizio **deve essere svolto su un branch dedicato**.
* **Non deve essere creato alcun file `OUTPUT.md`**.
* La verifica avverrà tramite:

  * branch;
  * commit;
  * contenuto del file YAML.

---

## Step 1 – Creazione del branch

Partendo dal branch principale (`master`):

```bash
git checkout master
git pull origin master
git checkout -b feature/<tuo_nome>-configmap
```

Esempio:

```bash
git checkout -b feature/leonardo-configmap
```

---

## Step 2 – Posizionarsi nella cartella dell’esercizio

Spostarsi nella directory:

```bash
cd exercises/03-k8s-configmap
```

---

## Step 3 – Creazione del file ConfigMap

Aprire il file `configmap.yaml` e definire una ConfigMap Kubernetes con le seguenti caratteristiche:

* `kind: ConfigMap`
* nome: `app-config`
* namespace: `default`
* chiavi obbligatorie:

  * `APP_NAME`
  * `APP_ENV`
  * `LOG_LEVEL`

### Esempio

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: default
data:
  APP_NAME: "sample-app"
  APP_ENV: "dev"
  LOG_LEVEL: "info"
```

---

## Step 4 – Validazione locale (opzionale)

Se si dispone di un cluster Kubernetes:

```bash
kubectl apply -f configmap.yaml
kubectl get configmap app-config
```

---

## Step 5 – Commit delle modifiche

```bash
git status
git add configmap.yaml
git commit -m "Aggiunta ConfigMap per configurazione applicativa"
```

---

## Step 6 – Push del branch

```bash
git push origin feature/<tuo_nome>-configmap
```

---

## Criteri di completamento

L’esercizio è considerato completato se:

* il branch esiste sul repository remoto;
* il file `configmap.yaml` è presente e corretto;
* il commit è chiaro e coerente.

