# Esercizio DevSecOps Intermedio – Flask Secure App su WSL

## Prerequisiti

- Windows con **WSL** installato
- Distribuzione **Ubuntu**
- Accesso a Internet
- Git installato

---

## Scenario
Il tuo team deve rilasciare una **micro web app Flask** in modo sicuro, partendo dallo sviluppo locale.

Il tuo compito è:
1. Preparare l’ambiente
2. Isolare le dipendenze
3. Avviare l’app
4. Analizzare i rischi di sicurezza
5. Migliorare la configurazione

---

## Avvio dell’ambiente WSL

Apri WSL:
- Premi **Win**
- Cerca **Ubuntu**
- Apri il terminale

Aggiorna il sistema:

```bash
sudo apt update && sudo apt upgrade -y
```

## Installazione Python e strumenti base se non li avete
```bash
sudo apt install -y python3 python3-pip python3-venv git
```

Verifica:
```bash
python3 --version
pip3 --version
```

## Clona il repository
git clone https://github.com/<ORG>/<REPO>.git
cd <REPO>


## Creazione Virtual Environment (Best Practice DevSecOps)
```bash
python3 -m venv venv
source venv/bin/activate
```
Verifica:
```bash
which python
Deve puntare a venv/bin/python.
```

## Installazione dipendenze
Installa Flask bloccando le versioni:
```bash
pip install flask==2.3.3
pip freeze > requirements.txt
```

Perché è importante
Versioni non bloccate = rischio supply chain
requirements.txt = riproducibilità

## Creazione del branch con il vostro nome a partire da master
git branch app/<tuo_nome>

## Creazione applicazione Flask
Crea il file app.py:

```python
from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello():
    return "Hello DevSecOps Team!"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
```

## forse per eseguirlo servono i permessi? scopri come ;)

## Avvio dell’applicazione
```bash
python3 app.py
```

Output atteso:
Running on http://0.0.0.0:8080/

Apri browser:
http://localhost:8080

## Analisi di sicurezza delle dipendenze (Security Step)
Installa pip-audit:
```bash
pip install pip-audit
```

Esegui la scansione:
```bash
pip-audit
```

Analizza:
CVE trovate
severity
librerie vulnerabili

## Hardening base dell’app Flask
Problema
Flask in modalità default espone:
stacktrace
debug implicito in ambienti errati

## Soluzione
Aggiorna app.py:

```python
if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=8080,
        debug=False
    )
```

## Extra (Facoltativo – livello avanzato)
Usa bandit per analisi SAST:

```bash
pip install bandit
bandit -r .

Aggiungi .gitignore:
```.gitignore
venv/
__pycache__/
*.pyc
```

## Pusha le modifiche di quello che hai fatto sul remote repo

```bash
git add .
git commit "esercizio python"
git push
```

Simula una vulnerabilità aggiornando Flask e rieseguendo pip-audit