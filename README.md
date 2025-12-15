# Studio Consip

Repo per studiare comandi GIT

# Setup Repository - README.md

Questo repository contiene lo script di inizializzazione `inizio.sh`. Segui questi passaggi per configurarlo.

## 1. Creare Personal Access Token (PAT) su GitHub
```
1. Vai su GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Clicca "Generate new token (classic)"
3. Seleziona scopes: `repo` (full access) 
4. Copia il token generato (lo vedrai solo una volta!)
```

## 2. Clonare Repository Privato GitHub

**Opzione SSH (raccomandata):**

```bash
git clone git@github.com:tuo-utente/tuo-repo.git
```

**Opzione HTTPS con PAT:**
```bash
[git clone https://github.com/tuo-utente/tuo-repo.git](https://github.com/ldellemonache94/studio-consip.git)
```
```
- Username: il tuo username GitHub
- Password: incolla il PAT (non la password normale!)
```

**Salva credenziali per sempre (opzionale):**
```bash
git config --global credential.helper store
```

## 2. Permessi ed Esecuzione inizio.sh

```bash
chmod +x inizio.sh          # Rendi eseguibile
ls -l inizio.sh             # Verifica permessi (-rwxr-xr-x)
./inizio.sh                 # Esegui lo script
```

## 3. Creare e Pushare Nuovo Branch

```bash
git checkout -b feature/<tuo-nome>     # Crea e passa al branch
git add .                               # Aggiungi modifiche
git commit -m "Descrizione commit"      # Crea commit
git push -u origin feature/<tuo-nome>  # Pusha e configura tracking
```

## Note Importanti

- Sostituisci `tuo-utente/tuo-repo.git` con l'URL reale
- Per HTTPS: si può anche usare il Personal Access Token come password
- Dopo il primo push, `git push` e `git pull` funzioneranno automaticamente
