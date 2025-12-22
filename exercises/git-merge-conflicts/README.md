# Esercizio 05 – Gestione dei conflitti di merge Git

**Nome cartella:** `05-git-merge-conflicts`

---

## Obiettivo

Questo esercizio ha lo scopo di fornire le basi per:

* comprendere cosa sono i **conflitti di merge** in Git;
* gestire correttamente conflitti tra branch;
* risolvere i conflitti in modo manuale e consapevole;
* tracciare correttamente la risoluzione tramite commit.

È un esercizio fondamentale per il lavoro quotidiano DevOps, specialmente in contesti collaborativi.

---

## Regole fondamentali

* L’esercizio **deve essere svolto su un branch dedicato**.
* Non devono essere creati file aggiuntivi oltre a quelli indicati.
* La verifica avverrà tramite:

  * branch;
  * commit;
  * corretta risoluzione del conflitto.

---

## Struttura della cartella

```
exercises/05-git-merge-conflicts/
├── README.md
├── file.txt
```

Il file `file.txt` verrà modificato intenzionalmente su più branch per generare un conflitto.

---

## Step 1 – Creazione del branch di lavoro

Partendo dal branch principale:

```bash
git checkout master
git pull origin master
git checkout -b feature/<tuo_nome>-merge-conflict
```

Esempio:

```bash
git checkout -b feature/leonardo-merge-conflict
```

---

## Step 2 – Modifica iniziale del file

Aprire il file `file.txt` e inserire il seguente contenuto:

```
Versione iniziale del file
```

Salvare il file, poi eseguire:

```bash
git add file.txt
git commit -m "Modifica iniziale del file per esercizio conflitti"
```

---

## Step 3 – Creazione di un secondo branch

Creare un secondo branch a partire da `master`:

```bash
git checkout master
git checkout -b feature/<tuo_nome>-conflict-alt
```

Esempio:

```bash
git checkout -b feature/leonardo-conflict-alt
```

---

## Step 4 – Modifica alternativa dello stesso file

Nel branch appena creato, modificare **la stessa riga** di `file.txt`:

```
Versione alternativa del file
```

Commit delle modifiche:

```bash
git add file.txt
git commit -m "Modifica alternativa del file per generare conflitto"
```

---

## Step 5 – Tentativo di merge e generazione del conflitto

Tornare al primo branch:

```bash
git checkout feature/<tuo_nome>-merge-conflict
git merge feature/<tuo_nome>-conflict-alt
```

A questo punto Git segnalerà un **merge conflict**.

---

## Step 6 – Analisi del conflitto

Aprire il file `file.txt`. Git mostrerà qualcosa di simile:

```
<<<<<<< HEAD
Versione iniziale del file
=======
Versione alternativa del file
>>>>>>> feature/<tuo_nome>-conflict-alt
```

---

## Step 7 – Risoluzione del conflitto

Risolvere manualmente il conflitto scegliendo una delle due versioni oppure combinandole, ad esempio:

```
Versione risolta del file
```

Rimuovere **tutti i marker di conflitto** (`<<<<<<<`, `=======`, `>>>>>>>`).

---

## Step 8 – Completamento del merge

Una volta risolto il conflitto:

```bash
git add file.txt
git commit -m "Risolto conflitto di merge su file.txt"
```

---

## Step 9 – Push del branch

```bash
git push origin feature/<tuo_nome>-merge-conflict
```

---

## Criteri di completamento

L’esercizio è considerato completato se:

* esiste il branch `feature/<tuo_nome>-merge-conflict` sul repository remoto;
* il merge è stato completato con successo;
* il file `file.txt` **non contiene marker di conflitto**;
* il commit di risoluzione è presente e descrittivo.

---

## Competenze acquisite

* Gestione avanzata dei branch Git
* Comprensione dei merge conflict
* Risoluzione manuale dei conflitti
* Best practice di versioning collaborativo

