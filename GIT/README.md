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

Risultato visivo

### Lo script demo.sh ti mostra live:

File presenti/assenti
git log prima/dopo
Problema MD5
Perché reset > revert

Durata totale esercizio: 3 minuti