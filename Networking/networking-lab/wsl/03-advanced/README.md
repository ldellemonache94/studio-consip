# ATTENZIONE AI COMANDI CHE LANCIATE NON MI PRENDO RESPONSABILITA' :)
***
# 🔴 03 - Networking avanzato su WSL/Linux

**Livello:** Avanzato  
**Strumenti:** bash avanzato, `curl`, `dig`, `tcpdump`, `traceroute`  
**Dove:** Shell WSL/Linux

---

## Esercizio 1 — Network health monitor completo

Crea il file `net-health.sh`:

```bash
cat > net-health.sh << 'EOF'
#!/usr/bin/env bash
# Uso: ./net-health.sh google.com github.com cloudflare.com

HOSTS=("$@")
if [ ${#HOSTS[@]} -eq 0 ]; then
  HOSTS=("google.com" "github.com" "1.1.1.1")
fi

printf "\n%-20s %-8s %-18s %-10s %-12s\n" "HOST" "PING" "IP" "HTTP" "LATENZA"
printf "%-20s %-8s %-18s %-10s %-12s\n" "----" "----" "--" "----" "-------"

for HOST in "${HOSTS[@]}"; do
  # PING
  if ping -c 1 -W 2 "$HOST" &>/dev/null; then
    PING="✅"
  else
    PING="❌"
  fi

  # DNS
  IP=$(dig +short "$HOST" 2>/dev/null | grep -E '^[0-9]+\.' | head -1)
  IP=${IP:-"N/A"}

  # HTTP + latenza
  RESULT=$(curl -s -o /dev/null \
    -w "%{http_code} %{time_total}" \
    --max-time 5 "https://$HOST" 2>/dev/null)
  CODE=$(echo "$RESULT" | awk '{print $1}')
  TIME=$(echo "$RESULT" | awk '{printf "%.2fs", $2}')

  if [[ "$CODE" =~ ^ ]]; then
    STATUS="✅ $CODE"
  else
    STATUS="❌ $CODE"
  fi

  printf "%-20s %-8s %-18s %-10s %-12s\n" "$HOST" "$PING" "$IP" "$STATUS" "$TIME"
done

echo ""
EOF

chmod +x net-health.sh
```

Ecco il contenuto **formattato correttamente in Markdown**:

````markdown
Esegui:

```bash
./net-health.sh google.com github.com cloudflare.com httpbin.org
````

**Estensione:** aggiungi un loop continuo con `watch`:

```bash
watch -n 5 "./net-health.sh google.com github.com"
```

---

# Esercizio 2 — HTTP tracer dettagliato

Crea `http-trace.sh`:

```bash
cat > http-trace.sh << 'EOF'
#!/usr/bin/env bash
# Uso: ./http-trace.sh https://google.com

URL=${1:-"https://google.com"}
DOMAIN=$(echo "$URL" | sed 's|https\?://||' | cut -d'/' -f1)

echo "======================================"
echo " HTTP Trace: $URL"
echo "======================================"

echo ""
echo "--- Risoluzione DNS ---"
IP=$(dig +short "$DOMAIN" | grep -E '^[0-9]+\.' | head -1)
echo "Dominio:  $DOMAIN"
echo "IP:       $IP"

echo ""
echo "--- Richiesta HTTP ---"
curl -s -o /dev/null \
  -w "Codice HTTP:         %{http_code}\n\
IP connessione:      %{remote_ip}:%{remote_port}\n\
Tempo DNS:           %{time_namelookup}s\n\
Tempo connessione:   %{time_connect}s\n\
Tempo TLS:           %{time_appconnect}s\n\
Tempo totale:        %{time_total}s\n\
Dati scaricati:      %{size_download} bytes\n" \
  -L "$URL"

echo ""
echo "--- Header risposta ---"
curl -sI -L "$URL" 2>/dev/null | head -15
EOF

chmod +x http-trace.sh
```

Esegui:

```bash
./http-trace.sh https://google.com
./http-trace.sh https://github.com
./http-trace.sh https://httpbin.org/get
```

### Domande

* Qual è la differenza tra `time_connect` e `time_appconnect`?
* Google impiega più tempo a rispondere di Cloudflare?

---

# Esercizio 3 — Simula problema DNS e diagnosticalo

```bash
# Guarda la configurazione DNS attuale
cat /etc/resolv.conf

# Fai un backup
sudo cp /etc/resolv.conf /etc/resolv.conf.bak

# Imposta un DNS inesistente (ATTENZIONE: rompe la risoluzione DNS)
echo "nameserver 1.2.3.4" | sudo tee /etc/resolv.conf

# Ora prova:
dig +timeout=3 google.com
curl --max-time 5 https://google.com || echo "FALLITO"

# Prova con IP diretto (bypassa DNS)
curl --max-time 5 https://142.250.180.46 || echo "FALLITO"

# Ripristina
sudo cp /etc/resolv.conf.bak /etc/resolv.conf
```

### Domande

* Cosa succede quando il **DNS è rotto** ma usi l'**IP diretto**?
* Collega questo scenario a un problema DNS in Kubernetes (**CoreDNS rotto**).
* Come diagnosticheresti questo problema **senza sapere a priori che il DNS è rotto**?

---

# Esercizio 4 — Costruisci il tuo Runbook

Scrivi un file `RUNBOOK.md` con la risposta a questo scenario:

> "Da WSL non riesco a raggiungere un servizio esterno (es. github.com) ma da browser Windows funziona. Cosa fai?"

Il runbook deve avere **almeno 8 step** con i relativi comandi e la spiegazione di cosa cerchi in ogni step.

### Struttura suggerita

```text
# Runbook: WSL non raggiunge Internet

## Sintomo
...

## Step 1 — Verifica connettività IP diretta
Comando: ...
Cosa cerchi: ...

## Step 2 — Verifica DNS
...
```

---

# Esercizio 5 — Challenge finale: integra tutto

Scrivi uno script `full-network-audit.sh` che:

* Mostra le **interfacce di rete attive** (`ip addr`)
* Mostra il **gateway e la tabella di routing**
* Mostra le **porte in ascolto con processo associato**
* Controlla la **risoluzione DNS** (testa `google.com`, `github.com`)
* Controlla la **connettività HTTP** verso 3 URL
* Esegue un **traceroute verso `8.8.8.8`** e mostra solo i primi **5 hop**
* Stampa un **riepilogo finale con tutti gli OK/KO**

Lo script deve produrre un **output leggibile**, con:

* sezioni separate
* timestamp
* colori ANSI

  * `\e[32m` → verde
  * `\e[31m` → rosso
  * `\e[0m` → reset

---

# Setup cartelle laboratorio

Crea le cartelle ed esegui questi comandi per impostare l'alberatura in un colpo solo:

```bash
mkdir -p networking-lab/{k8s/{01-basic-dns-curl,02-services-endpoints,03-network-policies,04-external-connectivity,05-advanced-debug},wsl/{01-basics,02-intermediate,03-advanced}}
```
