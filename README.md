# Studio Consip

Repo per studiare comandi GIT

# Setup Repository - README.md

Questo repository contiene lo script di inizializzazione `inizio.sh`. Segui questi passaggi per configurarlo.

## 1. Clonare Repository Privato GitHub

**Opzione cloning HTTPS:**

```
git clone https://<nome_utente>@github.com/tuo-utente/tuo-repo.git
```
### Vi verrà richiestra la password del vostro account per far partire il clone

## 2. Permessi ed Esecuzione inizio.sh

```
chmod +x inizio.sh          # Rendi eseguibile
ls -l inizio.sh             # Verifica permessi (-rwxr-xr-x)
./inizio.sh                 # Esegui lo script
```

## 3. Creare e Pushare Nuovo Branch

```bash
git checkout -b feature/nome-branch     # Crea e passa al branch
git add .                               # Aggiungi modifiche
git commit -m "Descrizione commit"      # Crea commit
git push -u origin feature/nome-branch  # Pusha e configura tracking
```

## Note Importanti

- Sostituisci `tuo-utente/tuo-repo.git` con l'URL reale
- Per HTTPS: si può anche usare il Personal Access Token come password
- Dopo il primo push, `git push` e `git pull` funzioneranno automaticamente


