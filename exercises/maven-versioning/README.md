# Esercizio 07 – Automazione con Bash e Maven (Versioning e Build)

## Obiettivo

Questo esercizio è pensato per fornire competenze **pratiche e realistiche** da DevOps su:

* scrittura di **script Bash**;
* automazione di task ripetitivi;
* gestione del **versioning Maven**;
* esecuzione di una **build Maven** con download delle dipendenze;
* comprensione di come questi passaggi vengano poi inseriti in **pipeline CI/CD**.

L’esercizio può essere:

* spiegato sulle slide (PP);
* eseguito localmente;
* facilmente riutilizzato in Jenkins / GitHub Actions / GitLab CI.

---

## Regole fondamentali

* L’esercizio deve essere svolto su un **branch feature dedicato**.
* Non creare file di output aggiuntivi.
* La verifica avverrà tramite:

  * branch;
  * script Bash;
  * modifica del `pom.xml`;
  * commit Git.

---

## Struttura della cartella

```
exercises/07-bash-maven-versioning/
├── README.md
├── pom.xml
├── build.sh
```

---

## Contesto

Si vuole simulare una **fase di CI** in cui:

1. viene aggiornata la versione di un progetto Maven;
2. vengono scaricate le dipendenze;
3. viene eseguita una build;
4. tutto è orchestrato tramite **script Bash**.

---

## Step 1 – Creazione del branch

```bash
git checkout master
git pull origin master
git checkout -b feature/<tuo_nome>-bash-maven
```

Esempio:

```bash
git checkout -b feature/leonardo-bash-maven
```

---

## Step 2 – Posizionarsi nella cartella dell’esercizio

```bash
cd exercises/07-bash-maven-versioning
```

---

## Step 3 – Configurazione del pom.xml

Nel file `pom.xml` deve essere presente almeno:

* `groupId`
* `artifactId`
* `version`
* una dipendenza a scelta (es. `slf4j` o `junit`)

### Esempio minimale

```xml
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">

  <modelVersion>4.0.0</modelVersion>

  <groupId>com.example</groupId>
  <artifactId>sample-app</artifactId>
  <version>1.0.0-SNAPSHOT</version>

  <dependencies>
    <dependency>
      <groupId>org.slf4j</groupId>
      <artifactId>slf4j-api</artifactId>
      <version>2.0.9</version>
    </dependency>
  </dependencies>

</project>
```

---

## Step 4 – Creazione dello script Bash

Aprire il file `build.sh` e implementare uno script che:

1. legge una nuova versione passata come parametro;
2. aggiorna la versione del progetto Maven;
3. scarica le dipendenze;
4. esegue la build.

### Comportamento atteso

Lo script deve essere eseguito così:

```bash
./build.sh 1.0.1-SNAPSHOT
```

---

## Step 5 – Esempio di script Bash

```bash
#!/bin/bash

set -e

if [ -z "$1" ]; then
  echo "Errore: versione non specificata"
  echo "Uso: ./build.sh <nuova-versione>"
  exit 1
fi

NEW_VERSION=$1

echo "Aggiornamento versione Maven a: $NEW_VERSION"

mvn versions:set -DnewVersion=$NEW_VERSION -DgenerateBackupPoms=false

echo "Download delle dipendenze"
mvn dependency:resolve

echo "Esecuzione build"
mvn clean package

echo "Build completata con successo"
```

Rendere lo script eseguibile:

```bash
chmod +x build.sh
```

---

## Step 6 – Esecuzione locale (opzionale)

```bash
./build.sh 1.0.1-SNAPSHOT
```

Verificare che:

* la versione nel `pom.xml` sia aggiornata;
* Maven abbia scaricato le dipendenze;
* la build termini con successo.

---

## Step 7 – Commit delle modifiche

```bash
git status
git add pom.xml build.sh
git commit -m "Aggiunto script Bash per versioning e build Maven"
```

---

## Step 8 – Push del branch

```bash
git push origin feature/<tuo_nome>-bash-maven
```

---

## Criteri di completamento

L’esercizio è considerato completato se:

* il branch feature è presente sul repository remoto;
* lo script Bash è funzionante;
* il `pom.xml` viene aggiornato correttamente;
* la build Maven viene eseguita senza errori;
* il commit è chiaro e descrittivo.

---

## Competenze acquisite

* Bash scripting per automazione
* Versioning Maven
* Gestione delle dipendenze
* Simulazione di una fase CI
* Base per pipeline Jenkins / CI/CD

