# studio-consip
Repo per studiare comandi GIT

# README.md - Setup Repository

Questo repository contiene lo script di inizializzazione `inizio.sh`.

## 1. Clonare Repository Privato GitHub

**SSH (raccomandato):**

git clone git@github.com:tuo-utente/tuo-repo.git

**HTTPS:**

git clone https://github.com/tuo-utente/tuo-repo.git


## 2. Eseguire inizio.sh

chmod +x inizio.sh      # Rendi eseguibile
./inizio.sh             # Esegui script

## 3. Creare e Push Nuovo Branch

git checkout -b feature/nome-branch
git add .
git commit -m "Descrizione modifiche"
git push -u origin feature/nome-branch

Sostituisci `tuo-utente/tuo-repo.git` con il tuo repository reale.[memory:15]
