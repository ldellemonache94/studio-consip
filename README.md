# Studio Consip
Repo per studiare comandi GIT
```markdown
# Setup Repository - README.md

Questo repository contiene lo script di inizializzazione `inizio.sh`. Segui questi passaggi per configurarlo.

## 1. Clonare Repository Privato GitHub

**Opzione SSH (raccomandata):**
```
git clone git@github.com:tuo-utente/tuo-repo.git
```

**Opzione HTTPS:**
```
git clone https://github.com/tuo-utente/tuo-repo.git
```

## 2. Permessi ed Esecuzione inizio.sh

```
chmod +x inizio.sh          # Rendi eseguibile
ls -l inizio.sh             # Verifica permessi (-rwxr-xr-x)
./inizio.sh                 # Esegui lo script
```

## 3. Creare e Pushare Nuovo Branch

```
git checkout -b feature/nome-branch     # Crea e passa al branch
git add .                               # Aggiungi modifiche
git commit -m "Descrizione commit"      # Crea commit
git push -u origin feature/nome-branch  # Pusha e configura tracking
```

## Note Importanti

- Sostituisci `tuo-utente/tuo-repo.git` con l'URL reale
- Per SSH: configura chiave SSH in GitHub Settings > SSH keys
- Per HTTPS: usa Personal Access Token come password
- Dopo il primo push, `git push` e `git pull` funzioneranno automaticamente
```

Copia e incolla questo contenuto nel file `README.md` del tuo repository GitHub![1]

[1](https://www.perplexity.ai/search/4d14bc5f-3cdf-40e4-9920-443c1995d51e)
