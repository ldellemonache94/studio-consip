# 🔌 telnet e nc (netcat) — Test di Connettività TCP/UDP

---

## Perché usare telnet e nc?

Immagina questa situazione:
- `ping` funziona → l'host è raggiungibile
- `dig` funziona → il DNS risolve
- `curl` non funziona → il servizio HTTP non risponde

**Dove si rompe?** È il servizio applicativo (HTTP) o la porta è chiusa?

`nc` (netcat) e `telnet` rispondono a questa domanda:
**testano se una specifica porta TCP è aperta e accetta connessioni**,
senza preoccuparsi del protocollo applicativo sopra.

ping → "L'host è vivo a livello IP?"
nc/telnet → "La porta TCP è aperta? Il servizio accetta connessioni?"
curl → "Il servizio HTTP risponde correttamente?"

---

## telnet vs nc: differenze

| Caratteristica | telnet | nc |
|---|---|---|
| Disponibilità | Quasi ovunque (legacy) | Da installare, ma più potente |
| Test porta TCP | ✅ Sì | ✅ Sì |
| Test porta UDP | ❌ No | ✅ Sì |
| Uso in script | ❌ Difficile | ✅ Ottimo (flag `-z`) |
| Modalità server | ❌ No | ✅ Sì (flag `-l`) |
| Trasferimento file | ❌ No | ✅ Sì |
| Raccomandato | Solo per test rapidi interattivi | Sempre preferire nc |

---

## VPN: come cambia il comportamento

### Scenario tipico: porta raggiungibile solo con VPN

```bash
# SENZA VPN
nc -zv db-interno.azienda.local 5432
# nc: getaddrinfo for host "db-interno.azienda.local" not found
# → Il DNS non risolve nemmeno (host interno)

# CON VPN attiva
nc -zv db-interno.azienda.local 5432
# Connection to db-interno.azienda.local port 5432 [tcp/postgresql] succeeded!
# → La porta è aperta e raggiungibile tramite VPN
```
Scenario: firewall VPN blocca certe porte
Alcune VPN aziendali bloccano porte specifiche (es. non puoi uscire su Internet
dalla porta 25 per evitare spam, o la porta 22 è bloccata verso Internet):

```bash
# Test porta 25 (SMTP) → spesso bloccata
nc -zv smtp.gmail.com 25
# Timeout → bloccata dal firewall VPN

# Test porta 587 (SMTP alternativo) → spesso aperta
nc -zv smtp.gmail.com 587
# succeeded! → questa funziona
```
Interpretare i risultati di nc
```bash
nc -zv hostname porta
```
Output	Significato
Connection to hostname port XX succeeded!	✅ La porta è aperta e il servizio accetta connessioni
Connection refused	❌ L'host è raggiungibile ma la porta è chiusa (nessun servizio in ascolto)
Timeout (operazione scaduta)	⚠️ Firewall sta bloccando silenziosamente (drop) o host non raggiungibile
No route to host	❌ Problema di routing: il pacchetto non sa come arrivare a destinazione
Name or service not known	❌ Problema DNS: il nome non si risolve

## Esempi pratici con spiegazione
1. Test porta TCP (l'uso più comune)
```bash
# Verifica se la porta 443 HTTPS è aperta
nc -zv google.com 443

# Verifica se PostgreSQL è raggiungibile
nc -zv db-host 5432

# Verifica se Redis è raggiungibile
nc -zv redis-host 6379

# Verifica se il broker Kafka è raggiungibile
nc -zv kafka-host 9092
```
-z → scan mode (non manda dati, testa solo la connessione)
-v → verbose (stampa il risultato in modo leggibile)

2. Test con timeout (per script)
```bash
# -w 3 = aspetta massimo 3 secondi
nc -zw3 hostname 8080

# In uno script
if nc -zw3 hostname 8080 2>/dev/null; then
  echo "Porta 8080 aperta"
else
  echo "Porta 8080 non raggiungibile"
fi
```
3. Test porta UDP
```bash
# DNS usa UDP sulla porta 53
nc -zuv 8.8.8.8 53

# NTP usa UDP sulla porta 123
nc -zuv pool.ntp.org 123
```
-u → modalità UDP. Attenzione: con UDP il risultato è meno affidabile
(UDP è connectionless), ma nc può comunque rilevare se la porta risponde.

4. Banner grabbing: scopri il servizio in ascolto
```bash
# SSH: mostra la versione del server SSH
echo "" | nc -w 2 hostname 22
# → SSH-2.0-OpenSSH_8.9p1 Ubuntu-3ubuntu0.6

# HTTP: mostra gli header del server web
printf "HEAD / HTTP/1.0\r\n\r\n" | nc -w 3 google.com 80
# → HTTP/1.0 301 Moved Permanently
# → Location: http://www.google.com/
```
Il banner grabbing ti dice che servizio gira su una porta e spesso
anche la sua versione, informazione critica per il troubleshooting.

5. Creare un server TCP temporaneo (per testing)
```bash
# Terminale 1: avvia un server TCP in ascolto sulla porta 9999
nc -l 9999

# Terminale 2: connettiti al server
nc localhost 9999

# Ora scrivi testo in uno dei due terminali: appare nell'altro
# Ctrl+C per chiudere la connessione
```
Uso pratico: testare che un client riesca a connettersi prima che il vero
servizio sia pronto. Molto utile in Kubernetes per testare la rete
prima di deployare l'applicazione.

6. Trasferimento file senza SCP o SFTP
```bash
# Utile quando non hai SSH/SCP ma hai nc

# Ricevente (avvia il server prima)
nc -l 9999 > file-ricevuto.txt

# Mittente
nc <IP-RICEVENTE> 9999 < file-da-inviare.txt
```
7. Scan di un range di porte
```bash
# Scansiona porte 1-1024 su un host
nc -zv hostname 1-1024 2>&1 | grep succeeded

# Porte comuni di database e servizi
for PORT in 22 80 443 3306 5432 6379 8080 8443 9092 27017; do
  if nc -zw1 hostname $PORT 2>/dev/null; then
    echo "✅ Porta $PORT: aperta"
  else
    echo "❌ Porta $PORT: chiusa"
  fi
done
```
8. Test in Kubernetes: verifica porta di un Service
```bash
# Da dentro un Pod, testa se un Service risponde sulla porta giusta
kubectl exec -it net-busybox -n lab-networking -- sh

# Testa che il Service sia raggiungibile sulla porta 80
nc -zv echo-svc 80

# Testa la porta dell'API server Kubernetes
nc -zv kubernetes.default 443

# Distingui Service vuoto (no endpoints) da porta chiusa
nc -zv mio-service 80
# → Connection refused = Service esiste ma nessun Pod risponde
# → Timeout = Service non esiste o firewall blocca
```
9. telnet: uso legacy ma ancora utile
```bash
# Test rapido porta HTTP
telnet google.com 80
# Poi digita: GET / HTTP/1.0 [Invio][Invio]

# Test porta HTTPS (non funziona per il contenuto, solo test connessione)
telnet google.com 443

# Se la connessione si apre → porta aperta
# Se "Connection refused" → porta chiusa
# Ctrl+] poi quit per uscire da telnet
```
Esercizi
🟢 Esercizio 1 — Test porte comuni
```bash
# Testa queste porte sui seguenti host e annota i risultati
nc -zv google.com 80
nc -zv google.com 443
nc -zv google.com 22
nc -zv github.com 22
nc -zv github.com 443
```
Domande:

google.com ha la porta 22 aperta? Perché?

github.com ha la porta 22 aperta? Perché sì o perché no?

Qual è la differenza tra "Connection refused" e "Timeout"?

🟢 Esercizio 2 — Banner grabbing SSH
```bash
# Cattura il banner SSH di github.com
echo "" | nc -w 2 github.com 22

# Che versione di OpenSSH usa GitHub?
🟡 Esercizio 3 — Chat tra terminali
bash
# In WSL, apri due terminali

# Terminale 1:
nc -l 5555

# Terminale 2:
nc localhost 5555

# Scrivi messaggi in entrambi i terminali e osserva
```
Domande:

La comunicazione è bidirezionale?

Cosa succede se chiudi uno dei due terminali?

🟡 Esercizio 4 — Script: verifica multi-host multi-porta
Crea service-check.sh:

```bash
cat > service-check.sh << 'SCRIPT'
#!/usr/bin/env bash
# Verifica raggiungibilità di servizi critici

declare -A SERVICES=(
  ["Google HTTP"]="google.com:80"
  ["Google HTTPS"]="google.com:443"
  ["GitHub SSH"]="github.com:22"
  ["GitHub HTTPS"]="github.com:443"
  ["Cloudflare DNS"]="1.1.1.1:53"
  ["Google DNS"]="8.8.8.8:53"
)

echo "=== Service Connectivity Check ==="
echo ""
printf "%-25s %-25s %-10s\n" "SERVIZIO" "HOST:PORTA" "STATO"
printf "%-25s %-25s %-10s\n" "--------" "---------" "-----"

for NAME in "${!SERVICES[@]}"; do
  TARGET="${SERVICES[$NAME]}"
  HOST=$(echo "$TARGET" | cut -d: -f1)
  PORT=$(echo "$TARGET" | cut -d: -f2)

  if nc -zw3 "$HOST" "$PORT" 2>/dev/null; then
    STATUS="✅ APERTA"
  else
    STATUS="❌ CHIUSA"
  fi

  printf "%-25s %-25s %-10s\n" "$NAME" "$TARGET" "$STATUS"
done
SCRIPT
```
```bash
chmod +x service-check.sh
./service-check.sh
```
🔴 Esercizio 5 — Troubleshooting scenario completo
Segui questi step come se stessi risolvendo un problema reale:

Scenario: "Il nostro servizio su httpbin.org porta 80 non risponde."

```bash
# Step 1: L'host è raggiungibile? (IP level)
ping -c 3 httpbin.org

# Step 2: Il DNS risolve?
dig +short httpbin.org

# Step 3: La porta è aperta?
nc -zv httpbin.org 80

# Step 4: Il servizio risponde HTTP?
curl -v http://httpbin.org/get

# Step 5: Misura le performance
curl -s -o /dev/null -w "DNS:%{time_namelookup}s TCP:%{time_connect}s TOTAL:%{time_total}s\n" http://httpbin.org/get
```
Ripeti l'esercizio con una porta sicuramente chiusa (es. httpbin.org:9999)
e analizza dove si ferma la catena di troubleshooting.