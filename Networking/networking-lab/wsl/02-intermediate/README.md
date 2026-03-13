# ATTENZIONE AI COMANDI CHE LANCIATE NON MI PRENDO RESPONSABILITA' :)
***
# 🟡 02 - Networking intermedio su WSL/Linux

**Livello:** Intermedio  
**Strumenti:** `nc`, `nmap`, `tcpdump`, `bash scripting`  
**Dove:** Shell WSL/Linux

---

## Esercizio 1 — Test di porta con nc (netcat)

```bash
# Verifica se una porta è aperta
nc -zv google.com 80
nc -zv google.com 443
nc -zv google.com 22

# Verifica porta UDP
nc -zvu 8.8.8.8 53

# Scan di un range di porte
nc -zv google.com 79-82

# Simula un server TCP in ascolto (terminale 1)
nc -l 9999

# Connettiti al server (terminale 2, in un nuovo tab WSL)
nc localhost 9999
# Ora digita testo: verrà inviato all'altro terminale
```

Ecco il contenuto **formattato correttamente in Markdown**:

### Domande

- `google.com:22` è **aperta** o **chiusa**?
- Cosa significa **Connection refused** vs **Timeout**?
- Riesci a mandare **messaggi tra i due terminali con `nc`**?

---

# Esercizio 2 — Port scanner con nmap

⚠️ Usa **nmap SOLO su host di tua proprietà** o su `localhost/127.0.0.1`.

```bash
# Scan porte comuni su localhost
nmap localhost

# Scan tutte le porte
nmap -p- localhost

# Scan porte specifiche
nmap -p 22,80,443,8080 localhost

# Rilevare servizi e versioni
nmap -sV localhost

# Ping scan (host discovery nella subnet WSL)
nmap -sn 172.17.0.0/24

# Scan veloce su un host test
# scanme.nmap.org è un host pubblico dedicato ai test
nmap scanme.nmap.org
```

### Domande

* Quali **porte sono aperte** sul tuo `localhost`?
* Riesci a rilevare la **versione di ssh** in ascolto?
* Cosa vedi sulla **subnet WSL**?

---

# Esercizio 3 — Script: URL health checker

Crea il file **`url-check.sh`**:

```bash
cat > url-check.sh << 'EOF'
#!/usr/bin/env bash
# Uso: ./url-check.sh urls.txt

FILE=${1:-urls.txt}

if [ ! -f "$FILE" ]; then
  echo "Crea un file $FILE con un URL per riga"
  exit 1
fi

printf "%-40s %-10s %s\n" "URL" "CODE" "STATO"
printf "%-40s %-10s %s\n" "---" "----" "-----"

while IFS= read -r url || [ -n "$url" ]; do
  [ -z "$url" ] && continue
  CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url" 2>/dev/null)
  if [[ "$CODE" =~ ^2|^3 ]]; then
    STATUS="✅ OK"
  else
    STATUS="❌ KO"
  fi
  printf "%-40s %-10s %s\n" "$url" "$CODE" "$STATUS"
done < "$FILE"
EOF

chmod +x url-check.sh
```

Crea il file **`urls.txt`**:

```bash
cat > urls.txt << 'EOF'
https://google.com
https://github.com
https://httpbin.org/status/200
https://httpbin.org/status/404
https://httpbin.org/status/500
https://questo-dominio-non-esiste-davvero.xyz
EOF
```

Esegui:

```bash
./url-check.sh urls.txt
```

**Estensione:**
Aggiungi una colonna con il **tempo di risposta** usando `%{time_total}` di `curl`.

---

# Esercizio 4 — Script: port scanner bash

Crea il file **`port-scan.sh`**:

```bash
cat > port-scan.sh << 'EOF'
#!/usr/bin/env bash
# Uso: ./port-scan.sh <host> [porta_inizio] [porta_fine]

HOST=${1:-"localhost"}
START=${2:-1}
END=${3:-1024}

echo "Scanning $HOST porte $START-$END ..."
echo ""

OPEN=()

for PORT in $(seq "$START" "$END"); do
  if nc -zw1 "$HOST" "$PORT" 2>/dev/null; then
    echo "✅ Porta $PORT: APERTA"
    OPEN+=("$PORT")
  fi
done

echo ""
echo "Porte aperte trovate: ${#OPEN[@]}"
echo "Lista: ${OPEN[*]}"
EOF

chmod +x port-scan.sh
```

Esegui:

```bash
# Scan porte 1-1024 su localhost
./port-scan.sh localhost 1 1024

# Scan porte comuni su un host
./port-scan.sh google.com 79 83
```

---

# Esercizio 5 — tcpdump: cattura il traffico

⚠️ Su **WSL** potrebbe richiedere `sudo`.
Su alcuni WSL il traffico di rete può essere limitato.

```bash
# Lista le interfacce disponibili
sudo tcpdump -D

# Cattura 20 pacchetti su eth0
sudo tcpdump -i eth0 -c 20

# Cattura solo traffico DNS (porta 53)
sudo tcpdump -i eth0 -n port 53 -c 20

# In un terminale: lancia tcpdump
sudo tcpdump -i eth0 -n port 53 -c 10 &

# Nell'altro terminale: genera traffico DNS
dig google.com

# Salva la cattura su file (apribile con Wireshark)
sudo tcpdump -i eth0 -w /tmp/capture.pcap -c 50

# Leggi il file salvato
sudo tcpdump -r /tmp/capture.pcap
```

### Domande

* Riesci a vedere le **query DNS in chiaro**?
* Quali **IP compaiono più frequentemente**?
* Come apriresti il file `.pcap` su Windows con **Wireshark**?

