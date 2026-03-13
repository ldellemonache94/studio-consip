# ATTENZIONE AI COMANDI CHE LANCIATE NON MI PRENDO RESPONSABILITA' :)
# 🌐 Networking Lab

Benvenuto nel laboratorio pratico di networking da riga di comando.

Questo repo contiene esercizi pratici divisi in due percorsi:

- **`k8s/`** → esercizi da fare **dentro un Pod Kubernetes** (busybox, netshoot)
- **`wsl/`** → esercizi da fare su **WSL/Linux** (Ubuntu consigliato)

Gli esercizi sono organizzati per livello di difficoltà crescente:

| Livello | Simbolo |
|---------|---------|
| Base | 🟢 |
| Intermedio | 🟡 |
| Avanzato | 🔴 |

## Come usare questo repository

1. Clona il repo o copia i file
2. Segui le cartelle in ordine numerico (01 → 02 → ...)
3. Ogni `README.md` contiene la spiegazione e gli esercizi da fare
4. Gli esercizi hanno soluzioni commentate alla fine di ogni sezione

## Prerequisiti generali

- WSL con Ubuntu (o qualsiasi Linux)
- `kubectl` configurato su un cluster (minikube, kind, k3d, AKS, OpenShift, ecc.)
- Strumenti installati: `curl`, `wget`, `ping`, `dig`, `nslookup`, `ss`, `nc`, `traceroute`

Installa gli strumenti mancanti su Ubuntu/WSL:

```bash
sudo apt update && sudo apt install -y \
  curl wget dnsutils netcat-openbsd \
  traceroute iputils-ping iproute2 \
  nmap tcpdump
