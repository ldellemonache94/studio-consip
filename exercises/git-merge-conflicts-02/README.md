# Git Merge Conflicts
## Cos'è un merge conflict (e perché succede)?
Immagina che tu e un collega stiate entrambi modificando lo stesso documento Word, ma ognuno sulla propria copia. Quando cercate di unire le modifiche, il sistema non sa quale versione tenere: la tua o quella del collega.

### Git si comporta esattamente così. Un merge conflict accade quando:

Due branch modificano la stessa riga dello stesso file

Git prova a unirli (merge) ma non può decidere da solo quale versione è quella "giusta"

Non è un errore — è Git che ti chiede: "Ehi, ho trovato due versioni diverse. Dimmi tu quale tenere."

## Obiettivo dell'esercizio
Imparerai a:
Provocare intenzionalmente un merge conflict
Leggere e interpretare i marker che Git inserisce nel file
Risolvere il conflitto manualmente
Completare il merge con un commit descrittivo

## Passo 1 – Preparazione: crea il tuo branch principale
Parti sempre dal branch aggiornato:

```bash
git checkout master
git pull origin master
git checkout -b feature/<tuo_nome>-merge-conflict
```

Esempio:

```bash
git checkout -b feature/leonardo-merge-conflict
```
## Passo 2 – Prima modifica al file
Apri file.txt e scrivi esattamente questo contenuto:

Versione iniziale del file

Salva il file, poi committa:

```bash
git add file.txt
git commit -m "Modifica iniziale del file per esercizio conflitti"
```

Ora il tuo branch feature/<tuo_nome>-merge-conflict ha una versione del file.

## Passo 3 – Crea un secondo branch (il "rivale")
Torna su master e crea un secondo branch separato:

```bash
git checkout master
git checkout -b feature/<tuo_nome>-conflict-alt
```
Questo simula un collega che ha lavorato sullo stesso file in parallelo a te.

## Passo 4 – Modifica alternativa dello stesso file
In questo nuovo branch, apri file.txt e scrivi una versione diversa sulla stessa riga:

Versione alternativa del file

Committa:

```bash
git add file.txt
git commit -m "Modifica alternativa del file per generare conflitto"
```

Ora hai due branch con due versioni diverse dello stesso file. Il conflitto è pronto.

## Passo 5 – Prova il merge e osserva il conflitto

Torna al tuo branch principale e prova a unire il branch "rivale":

```bash
git checkout feature/<tuo_nome>-merge-conflict
git merge feature/<tuo_nome>-conflict-alt
```
Git ti mostrerà un messaggio simile a:

CONFLICT (content): Merge conflict in file.txt
Automatic merge failed; fix conflicts and then commit the result.
Non farti prendere dal panico — è esattamente quello che volevamo.

## Passo 6 – Leggi il conflitto nel file
Apri file.txt. Git ha modificato il file aggiungendo dei marker visivi:

<<<<<<< HEAD
Versione iniziale del file
=======
Versione alternativa del file
>>>>>>> feature/<tuo_nome>-conflict-alt


Ecco come leggerli:

Marker	Significato
<<<<<<< HEAD	Inizio della tua versione (branch attuale)
=======	Separatore tra le due versioni
>>>>>>> feature/...	Fine della versione del branch che stai unendo

## Passo 7 – Risolvi il conflitto manualmente
Devi scegliere tu cosa tenere. Hai tre opzioni:

### Opzione A – Tieni la tua versione:

Versione iniziale del file

### Opzione B – Tieni la versione alternativa:

Versione alternativa del file

### Opzione C – Combina entrambe (la più comune nel lavoro reale):

Versione risolta del file
Qualunque opzione scegli, assicurati di eliminare completamente le righe con <<<<<<<, ======= e >>>>>>>. Se restano nel file, il merge non è risolto.

### Passo 8 – Completa il merge
Una volta che il file è pulito e senza marker:

```bash
git add file.txt
git commit -m "Risolto conflitto di merge su file.txt"
```

### Passo 9 – Pusha il branch
```bash
git push origin feature/<tuo_nome>-merge-conflict
```

Criteri di completamento
 - Il branch feature/<tuo_nome>-merge-conflict esiste sul repository remoto
 - Il merge è stato completato senza errori
 - file.txt non contiene marker di conflitto (<<<<<<<, =======, >>>>>>>)
 - È presente un commit di risoluzione con messaggio descrittivo

Competenze acquisite
Comprensione pratica del merge conflict
Lettura e interpretazione dei marker Git
Risoluzione manuale dei conflitti
Best practice di versioning collaborativo

