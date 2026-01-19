````md
# Guida Completa: Hello World Flask su WSL

Trasforma il tuo programma Python in un'app web utilizzando Flask su WSL (Windows Subsystem for Linux).
## Clona il repository sulla tua WSL

## 1. Apri WSL
Premi **Win**, cerca **Ubuntu** e apri il terminale.

## 2. Clona il repository sulla tua WSL
git clone <url>

## 3. Installa Python 3
```bash
sudo apt update
sudo apt install -y python3 python3-pip
````

## 4. Installa Flask

```bash
pip3 install flask
```

## 5. Esegui il file `hello.py`

Posizionati nella directory dove si trova il file ed esegui:

```bash
python3 hello.py
```

Output atteso:

```text
* Running on http://0.0.0.0:8080/
```

## 6. Apri il browser

Apri il browser su Windows e vai su:

```
http://localhost:8080
```