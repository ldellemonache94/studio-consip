# ATTENZIONE AI COMANDI CHE LANCIATE NON MI PRENDO RESPONSABILITA' :)
***
# 🐧 WSL/Linux Networking Lab

Esercizi di networking su Linux (Ubuntu WSL consigliato).

## Struttura esercizi

| Cartella | Argomento | Livello |
|---|---|---|
| `01-basics/` | Comandi fondamentali: ping, curl, dig, ip | 🟢 Base |
| `02-intermediate/` | Scripting, sniffing, analisi porte | 🟡 Intermedio |
| `03-advanced/` | Tool custom, scenari di debug, runbook | 🔴 Avanzato |

## Setup iniziale

Installa gli strumenti su Ubuntu/WSL:

```bash
sudo apt update && sudo apt install -y \
  curl wget dnsutils netcat-openbsd \
  traceroute iputils-ping iproute2 \
  nmap tcpdump jq
```

## Verifica
```bash
curl --version
dig -v 2>&1 | head -1
nmap --version
```
