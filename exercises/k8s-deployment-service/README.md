# Esercizio 06 – Creazione di un Deployment e di un Service Kubernetes

## Obiettivo

Questo esercizio ha lo scopo di fornire le basi per:

* lavorare su **branch dedicati**;
* creare un **Deployment Kubernetes**;
* esporre un’applicazione tramite un **Service**;
* comprendere il legame tra Pod, Deployment e Service.

Si tratta di una competenza fondamentale per un DevOps che lavora con Kubernetes.

---

## Regole fondamentali

* L’esercizio deve essere svolto su un **branch feature dedicato**.
* La verifica avverrà tramite:

  * branch;
  * commit;
  * correttezza dei file YAML.

---

## Struttura della cartella

```
exercises/06-k8s-deployment-service/
├── README.md
├── deployment.yaml
├── service.yaml
```

---

## Step 1 – Creazione del branch

Partendo dal branch principale:

```bash
git checkout master
git pull origin master
git checkout -b feature/<tuo_nome>-deployment-service
```

Esempio:

```bash
git checkout -b feature/leonardo-deployment-service
```

---

## Step 2 – Posizionarsi nella cartella dell’esercizio

```bash
cd exercises/06-k8s-deployment-service
```

---

## Step 3 – Creazione del Deployment

Aprire il file `deployment.yaml` e definire un Deployment con le seguenti caratteristiche:

* `kind: Deployment`
* nome: `sample-app`
* repliche: `2`
* immagine container: `nginx:latest`
* label: `app: sample-app`

### Esempio di Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: sample-app
  template:
    metadata:
      labels:
        app: sample-app
    spec:
      containers:
        - name: nginx
          image: nginx:latest
          ports:
            - containerPort: 80
```

---

## Step 4 – Creazione del Service

Aprire il file `service.yaml` e definire un Service con le seguenti caratteristiche:

* `kind: Service`
* tipo: `ClusterIP`
* nome: `sample-app-service`
* porta: `80`
* selector coerente con il Deployment

### Esempio di Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: sample-app-service
spec:
  type: ClusterIP
  selector:
    app: sample-app
  ports:
    - port: 80
      targetPort: 80
```

---

## Step 5 – Validazione locale (opzionale)

Se si dispone di un cluster Kubernetes:

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl get pods
kubectl get svc
```

---

## Step 6 – Commit delle modifiche

```bash
git status
git add deployment.yaml service.yaml
git commit -m "Aggiunti Deployment e Service Kubernetes per sample-app"
```

---

## Step 7 – Push del branch

```bash
git push origin feature/<tuo_nome>-deployment-service
```

---

## Criteri di completamento

L’esercizio è considerato completato se:

* il branch è presente sul repository remoto;
* `deployment.yaml` è sintatticamente corretto;
* `service.yaml` espone correttamente il Deployment;
* i label e selector sono coerenti;
* il commit è chiaro e descrittivo.

---

## Competenze acquisite

* Gestione dei Deployment Kubernetes
* Esposizione delle applicazioni con i Service
* Comprensione del networking base in Kubernetes
* Best practice di versionamento YAML

