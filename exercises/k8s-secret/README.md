# Esercizio 04 – Gestione di un Secret Kubernetes

## Obiettivo

Questo esercizio ha lo scopo di:

* lavorare correttamente su **branch feature**;
* creare e versionare un **Secret Kubernetes**;
* comprendere la gestione dei dati sensibili su Kubernetes.

---

## Regole fondamentali

* L’esercizio deve essere svolto su un **branch dedicato**.
* Le evidenze saranno:

  * branch;
  * commit;
  * correttezza del file `secret.yaml`.

---

## Step 1 – Creazione del branch

Partendo dal branch principale:

```bash
git checkout master
git pull origin master
git checkout -b feature/<tuo_nome>-secret
```

Esempio:

```bash
git checkout -b feature/leonardo-secret
```

---

## Step 2 – Posizionarsi nella cartella dell’esercizio

```bash
cd exercises/04-k8s-secret
```

---

## Step 3 – Codifica dei valori in base64

Convertire le credenziali in base64:

```bash
echo -n "devuser" | base64
echo -n "password" | base64
```

Salvare i valori ottenuti.

---

## Step 4 – Creazione del file Secret

Aprire il file `secret.yaml` e definire:

* `kind: Secret`
* tipo: `Opaque`
* nome: `db-secret`
* chiavi obbligatorie:

  * `DB_USERNAME`
  * `DB_PASSWORD`

### Esempio

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
  namespace: default
type: Opaque
data:
  DB_USERNAME: ZGV2dXNlcg==
  DB_PASSWORD: cGFzc3dvcmQ=
```

---

## Step 5 – Validazione locale (opzionale)

```bash
kubectl apply -f secret.yaml
kubectl get secret db-secret
```

---

## Step 6 – Commit delle modifiche

```bash
git status
git add secret.yaml
git commit -m "Aggiunto Secret Kubernetes per credenziali DB"
```

---

## Step 7 – Push del branch

```bash
git push origin feature/<tuo_nome>-secret
```

---

## Criteri di completamento

L’esercizio è completato se:

* il branch è presente sul repository remoto;
* il Secret è sintatticamente corretto;
* i dati sono correttamente codificati in base64;
* il commit è chiaro e descrittivo.

