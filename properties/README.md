# Guida alla creazione di un branch feature e modifica dei file properties

Questa guida descrive i passaggi necessari per:

* creare un nuovo branch a partire dal branch di riferimento;
* utilizzare una nomenclatura standard per il branch;
* modificare un file di configurazione (`generic.properties` o `general.properties`);
* versionare e pubblicare le modifiche tramite Git.

---

## 1. Prerequisiti

Prima di procedere, assicurarsi di avere:

* Git installato sul proprio sistema;
* accesso al repository remoto;
* il repository già clonato in locale.

---

## 2. Posizionarsi sul branch di partenza

Entrare nella directory del repository ed assicurarsi di essere sul branch di partenza (ad esempio `master` o `develop`).

```bash
git checkout master
git pull origin master
```

> **Nota**: sostituire `master` con il branch corretto, se diverso.

---

## 3. Creazione del nuovo branch feature

Creare un nuovo branch utilizzando la seguente nomenclatura:

```
feature/<tuo_nome>-properties
```

Eseguire il comando:

```bash
git checkout -b feature/<tuo_nome>-properties
```

Esempio:

```bash
git checkout -b feature/leonardo-properties
```

---

## 4. Modifica del file properties

All'interno del repository individuare uno dei seguenti file:

* `generic.properties`
* `general.properties`

Aprire il file scelto e aggiungere un nuovo obiettivo (chiave-valore) a piacere.

### Esempio di modifica

```properties
# Nuovo obiettivo aggiunto
app.new.goal=Completare la configurazione delle properties
```

Salvare il file dopo la modifica.

---

## 5. Verifica delle modifiche

Controllare lo stato del repository per verificare i file modificati:

```bash
git status
```

---

## 6. Aggiunta delle modifiche all'area di staging

Aggiungere il file modificato allo staging:

```bash
git add generic.properties
```

oppure, se è stato modificato l'altro file:

```bash
git add general.properties
```

---

## 7. Commit delle modifiche

Creare un commit con un messaggio chiaro e descrittivo:

```bash
git commit -m "Aggiunto nuovo obiettivo nel file properties"
```

---

## 8. Push del branch sul repository remoto

Pubblicare il branch appena creato sul repository remoto:

```bash
git push origin feature/<tuo_nome>-properties
```

Esempio:

```bash
git push origin feature/leonardo-properties
```

---

## 9. Merge del branch feature su master

Una volta completate le modifiche e dopo eventuali revisioni (Merge Request / Pull Request), è possibile procedere con il merge del branch feature sul branch `master`.

### 9.1 Posizionarsi sul branch master

```bash
git checkout master
git pull origin master
```

### 9.2 Eseguire il merge del branch feature

```bash
git merge feature/<tuo_nome>-properties
```

Esempio:

```bash
git merge feature/leonardo-properties
```

### 9.3 Risoluzione di eventuali conflitti

Se durante il merge vengono segnalati conflitti:

1. risolvere manualmente i conflitti nei file indicati;
2. aggiungere i file risolti allo staging;
3. completare il merge con un commit.

```bash
git add .
git commit -m "Risolti conflitti di merge"
```

### 9.4 Push delle modifiche su master

Infine, pubblicare il branch `master` aggiornato sul repository remoto:

```bash
git push origin master
```

A questo punto il branch feature è stato correttamente integrato nel branch `master`.
