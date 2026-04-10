# GitFlow Demo: Perché NON fare `git revert` su branch RC

Questo repository dimostra **perché evitare `git revert`** su un branch **release candidate (RC)** nel vostro flusso Git custom, dove `rc` → pre-prod (MD5 verificato) → prod → merge su `master`.



## Il vostro flusso in breve
```
develop → sviluppo
     ↓
rc/vX.X.X → pre-prod (build + MD5) → produzione → merge su master
```

**Problema**: Su `rc` aggiungi codice "sbagliato". Come lo rimuovi senza rompere tutto?

## Scenario pratico

Partiamo da `develop` pulito:

```
git checkout develop
git checkout -b rc/v1.0.0-<tuo-nome>
```

### Passo 1: Aggiungi codice "sbagliato" (simulato in `feature-bug.txt`)
```bash
echo "Feature che NON va in PROD" > feature-bug.txt
git add feature-bug.txt
git commit -m "feat: aggiunta feature sbagliata"
git push origin rc/v1.0.0-<tuo-nome>
```

**Pre-prod OK**: Build + MD5 calcolato = `abc123...`

***

## OPZIONE SBAGLIATA: `git revert`

```bash
git checkout rc/v1.0.0-<tuo-nome>
git revert HEAD
git push origin rc/v1.0.0-<tuo-nome>
```

### Cosa succede?

| Problema | Conseguenza |
|----------|-------------|
| **Nuovo commit** `Revert "feat: aggiunta feature sbagliata"` | Storia con 2 commit inutili |
| **MD5 CAMBIA** | Deploy prod **FALLISCE** |
| **Storia sporca** | `feat` + `revert` = confusione in review |
| **Merge su master** | Porta commit inutili + potenziali conflitti |

**Git log dopo revert**:
```
* abc456 Revert "feat: aggiunta feature sbagliata"
* abc123 feat: aggiunta feature sbagliata
```

***

## OPZIONE CORRETTA: `git reset --hard`

```bash
git checkout rc/v1.0.0-<tuo-nome>
git reset --hard HEAD~1     # Torna PRIMA del commit sbagliato
git push origin rc/v1.0.0-<tuo-nome> --force-with-lease  # Sicuro per team, studiare il flag --force-with-lease!!!
```

### Risultato?

| Vantaggio | Beneficio |
|-----------|-----------|
| **Commit ELIMINATO** | Storia pulita |
| **MD5 IDENTICO** | Deploy prod OK |
| **Merge pulito** | Solo codice buono su `master` |
| **Facile da leggere** | Team capisce subito |

**Git log dopo reset**:
```
* def789 Codice base corretto
```

***

## Testa tu stesso!

### File nel repo:
```
├── app.txt              # Codice base
├── feature-bug.txt      # Feature da rimuovere
└── demo.sh              # Script interattivo
```

**Esegui demo**:
```bash
chmod +x demo.sh
./demo.sh
```

Lo script mostra **prima/dopo** revert vs reset, con MD5 e git log.

***

## Comandi completi passo-passo

### Setup iniziale:
```bash
git checkout -b develop
echo "Versione base app" > app.txt
git add app.txt && git commit -m "init: app base"
git push origin develop
```

### Crea RC + errore:
```bash
git checkout develop
git checkout -b rc/v1.0.0-<tuo-nome>
echo "FEATURE SBAGLIATA" > feature-bug.txt
git add feature-bug.txt && git commit -m "feat: feature sbagliata"
git push origin rc/v1.0.0-<tuo-nome>
```

### Test revert:
```bash
git revert HEAD && git push
git log --oneline -3
md5sum *txt  # MD5 CAMBIATO!
```

### Test reset:
```bash
git reset --hard HEAD~1
git push --force-with-lease
git log --oneline -1
md5sum *txt  # MD5 ORIGINALE!
```

***

## Perché il capo insiste?

1. **Pre-produzione**: Branch `rc` = codice testato. Revert = cambia hash
2. **Produzione**: MD5 deve matchare **esattamente** pre-prod
3. **Master**: Merge deve essere pulito, senza "revert" inutili
4. **Team**: Storia chiara = meno errori futuri

**Regola d'oro**: Su `rc` usa solo commit **forward** (bug fix). Per rimuovere, **reset** prima del merge.

***

## Quando SI può usare revert?

- Su `develop` (sviluppo)
- Su `master` post-produzione
- Su branch già mergiati/pubblici

**NON su RC** prima di produzione.

***

> **Lezione**: Un branch RC deve essere **puro**. Reset = storia pulita. Revert = correzione postuma. Scegli reset quando puoi!


## ESERCIZIO PASSO PASSO !!!

- 1. Setup iniziale (repo pulito)
## Da master/main crea develop
```bash
git checkout -b develop
echo "Versione base app" > app.txt
git add app.txt 
git commit -m "init: app base"
git push origin develop
```
- 2. Crea branch RC + aggiungi "errore"
```bash
git checkout develop
git checkout -b rc/v1.0.0
cp feature-bug.txt .          # Simula feature mergiata da develop
git add feature-bug.txt
git commit -m "feat: feature sbagliata (da develop)"
git push origin rc/v1.0.0
```

## Ora hai RC con feature-bug.txt (come pre-prod)

- 3. Testa le 2 opzioni

## Opzione 1 - Revert (SBAGLIATO):

```bash
git checkout rc/v1.0.0
git revert HEAD
git push origin rc/v1.0.0
```
./demo.sh  # Vedrai MD5 cambiato + storia sporca

## Opzione 2 - Reset (CORRETTO):

```bash
git checkout rc/v1.0.0        # Torna allo stato con bug
git reset --hard HEAD~1       # Rimuovi commit feature-bug
git push origin rc/v1.0.0 --force-with-lease
```
./demo.sh  # Vedrai storia pulita + MD5 originale

- 4. Simulazione finale merge

```bash
git checkout master
git merge rc/v1.0.0           # Merge pulito (senza feature-bug!)
git tag v1.0.0
git push origin master --tags
```

## Perché in questo progetto usiamo un Gitflow custom
1. In questo repository non stiamo usando Gitflow “classico” in modo rigido, ma un flusso adattato al nostro processo reale. develop è il ramo di sviluppo, rc è il ramo che viene costruito, verificato e portato in pre-produzione, e da lì lo stesso identico codice viene promosso in produzione; solo dopo il rilascio il branch rc viene mergiato in master.

2. Questa scelta ha un obiettivo preciso: fare in modo che il codice promosso sia sempre lo stesso che è stato testato, validato e approvato. In altre parole, il branch RC deve restare il più possibile stabile, lineare e rappresentativo del rilascio finale.

3. Il punto importante è che nel nostro processo non vogliamo “correggere la cronologia” con commit di annullamento quando un pezzo di codice deve solo essere rimandato. Se una modifica è sbagliata in modo definitivo, allora si può annullare; ma se quella modifica deve semplicemente comparire più avanti, il revert rischia di farla sparire dalla storia in un modo che poi confonde i merge successivi.

### Perché il revert è sconsigliato qui
- git revert crea un nuovo commit che annulla gli effetti di un commit precedente, ma non cancella quel commit dalla storia. Questo è il motivo per cui, in un branch RC o in un flusso in cui i merge devono restare coerenti nel tempo, il revert può diventare un problema: il codice sparisce dal contenuto del branch, ma nella cronologia il commit originale resta ancora presente.

- Quando più avanti provi a riportare dentro quelle modifiche con un nuovo merge, Git può considerare quel contenuto come “già noto” e quindi non riapplicarlo come ti aspetteresti. È proprio il tipo di comportamento che il tuo capo ti stava descrivendo: le modifiche non tornano più in modo naturale perché Git vede già quei commit nella storia.

- Questo è il punto chiave del nostro processo: se una modifica deve solo essere posticipata, il revert non è lo strumento giusto. Il revert è più adatto quando un commit è sbagliato e non dovrà più comparire in quel branch né in alcun altro ramo derivato da quel percorso. Se invece quel pezzo di codice deve semplicemente tornare più avanti, il revert rischia di “segnarlo” come già gestito, e il merge futuro non lo ripropone come previsto.

## Esempio concreto

### Immagina questa sequenza:

1. Uno sviluppatore introduce una modifica in develop.

2. La modifica viene portata nel branch rc.

3. In pre-produzione si decide che quella modifica non deve andare subito in produzione.

### A questo punto si fanno due scelte possibili:

- git revert, oppure

- git reset --hard prima che il branch venga consolidato.

Se fai git revert, la modifica sparisce dal contenuto del branch, ma il commit resta nella storia. Più avanti, se quel branch o una sua evoluzione torna a ricevere merge da develop, Git può non “rivedere” quella modifica come una novità, perché dal suo punto di vista il commit esiste già.

Il risultato pratico è frustrante: tu ti aspetti che la modifica riemerga, ma non succede, oppure succede in modo non lineare e difficile da leggere nella cronologia.

Con git reset --hard, invece, il commit viene tolto dalla storia del branch corrente prima che quel ramo venga consolidato. Questo lascia il branch più pulito e più adatto al nostro flusso, in cui il branch RC deve rappresentare in modo chiaro la release effettiva e non una sequenza di “aggiunte + annullamenti”.
In questo senso, il reset è più coerente quando l’operazione da fare è solo rimandare una modifica, non cancellarla definitivamente.


text
## Perché su questo progetto il revert è sconsigliato

In questo repository usiamo un Gitflow custom:

- `develop` è il branch di sviluppo.
- `rc` è il branch di release candidate.
- Il codice su `rc` viene buildato, testato e portato in pre-produzione.
- Lo stesso codice viene poi promosso in produzione.
- Dopo il rilascio, `rc` viene mergiato in `master`.

Questo significa che il branch `rc` deve rimanere il più possibile pulito e coerente con la release finale.

### Perché non usiamo `git revert` in questo caso

`git revert` non elimina davvero un commit dalla storia: aggiunge un nuovo commit che annulla il precedente.  
Questo va bene quando vuoi annullare in modo sicuro un cambiamento già pubblicato, ma nel nostro flusso può creare problemi perché:

- il commit originale resta nella history;
- i merge futuri possono non riproporre correttamente le modifiche;
- il branch diventa più difficile da leggere e da mantenere;
- si rischiano comportamenti inattesi quando un codice deve essere solo posticipato e non eliminato definitivamente.

### Esempio pratico

Supponiamo che una modifica entri in `rc`, ma poi si scopra che deve andare in produzione solo più tardi.

Se facciamo:

```bash
git revert mmit>
```

la modifica viene annullata nel contenuto del branch, ma il commit resta nella storia.  
Se in futuro rifacciamo un merge da `develop`, Git può considerare quel contenuto già noto e non riportarlo come ci aspettiamo.

Se invece facciamo:

```bash
git reset --hard mmit_precedente>
```

il branch torna a uno stato precedente e la storia resta più pulita.  
Quando la modifica verrà ripresa nel momento giusto, potrà essere reintrodotta in modo più chiaro e naturale.

### Regola pratica

- Usa `revert` solo quando il commit è sbagliato e non deve più comparire in quel percorso.
- Usa `reset` quando la modifica deve solo essere rimandata e il branch non è ancora stato consolidato.
La frase più importante da tenere nel README
Puoi anche aggiungere questa frase finale, che riassume bene il concetto:

In questo progetto non evitiamo il revert perché “funziona male” in assoluto, ma perché il nostro flusso richiede che il branch RC resti una rappresentazione fedele della release finale. Se una modifica deve solo essere posticipata, il revert lascia tracce nella storia che possono impedire un merge futuro pulito; per questo, quando possibile, preferiamo un reset prima che il branch venga consolidato.

