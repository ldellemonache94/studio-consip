# 📡 ping — "L'Host è Vivo?"

---

## Perché usare ping?

`ping` è il **primo controllo** che fai sempre, prima di qualsiasi altra cosa.

Funziona mandando pacchetti **ICMP Echo Request** e aspettando i corrispondenti
**ICMP Echo Reply**. Se l'host risponde → è raggiungibile a livello IP.
Se non risponde → o è giù, o c'è un problema di routing, o il firewall
blocca ICMP (attenzione: questa terza opzione è molto comune!).

Il valore di `ping` è nella sua **semplicità**: in un secondo ti dice se hai
connettività IP verso un host. Non devi capire HTTP, non devi sapere quale
porta è aperta. Solo: "sei vivo?"

---

## La catena di troubleshooting: ping viene PRIMA

ping 8.8.8.8 ← Testa la rete IP (bypassando il DNS)
ping google.com ← Testa rete IP + DNS insieme

Se ping 8.8.8.8 funziona ma ping google.com no → problema DNS
Se ping 8.8.8.8 non funziona → problema di rete/routing

---

## VPN: il caso più importante per ping

Quando sei sotto VPN, il comportamento di `ping` cambia drasticamente
ed è fonte di molta confusione.

### Scenario 1 — Ping bloccato dalla VPN (firewall)

```bash
ping server-interno.azienda.local
# Request timeout for icmp_seq 0
# Request timeout for icmp_seq 1
```
Non significa che il server sia giù!
Significa che il firewall aziendale blocca ICMP.
In questo caso, usa curl o nc per verificare:

```bash
# Se questo funziona, il server è vivo
nc -zv server-interno.azienda.local 443
curl -s -o /dev/null -w "%{http_code}" https://server-interno.azienda.local
```
Scenario 2 — Ping funziona ma il servizio no
```bash
ping server-interno.azienda.local   # ← risponde!
curl https://server-interno.azienda.local  # ← non risponde!
```
Il server è raggiungibile a livello IP ma il servizio applicativo ha problemi.
Vai avanti nella catena: testa la porta con nc, poi l'HTTP con curl.

Scenario 3 — Ping verso IP interni senza VPN
```bash
ping 10.0.1.50   # ← timeout se non sei in VPN
# → Rete privata aziendale non raggiungibile senza VPN
```
Interpretare l'output

```bash
ping -c 5 google.com
```
### Output tipico:

PING google.com (142.250.180.46): 56 data bytes
64 bytes from 142.250.180.46: icmp_seq=0 ttl=117 time=12.3 ms
64 bytes from 142.250.180.46: icmp_seq=1 ttl=117 time=11.8 ms
64 bytes from 142.250.180.46: icmp_seq=2 ttl=117 time=13.1 ms
64 bytes from 142.250.180.46: icmp_seq=3 ttl=117 time=12.0 ms
64 bytes from 142.250.180.46: icmp_seq=4 ttl=117 time=11.9 ms

--- google.com ping statistics ---
5 packets transmitted, 5 received, 0% packet loss
rtt min/avg/max/mdev = 11.8/12.2/13.1/0.4 ms
Campo	Significato
ttl=117	Hop rimanenti: quanti router può ancora attraversare
time=12.3 ms	RTT (Round Trip Time): latenza andata + ritorno
0% packet loss	Nessun pacchetto perso → connessione stabile
mdev=0.4 ms	Deviazione standard: quanto è stabile la latenza

### Segnali di allarme

# Packet loss > 0%
5 packets transmitted, 3 received, 40% packet loss
→ Rete instabile o congestionata

# RTT altissimo
time=2340 ms
→ Latenza elevata (VPN su server lontano, rete congestionata)

# TTL=1
ttl=1 → il pacchetto è già quasi esaurito, host a molti hop di distanza
Esempi pratici con spiegazione
1. Il classico: è vivo?
```bash
ping -c 4 8.8.8.8       # Controlla connettività IP (senza DNS)
ping -c 4 google.com    # Controlla IP + DNS
```
Se il primo funziona e il secondo no → DNS rotto.

2. Misura la latenza verso destinazioni diverse
```bash
ping -c 10 -q 1.1.1.1          # Cloudflare
ping -c 10 -q 8.8.8.8          # Google
ping -c 10 -q 208.67.222.222   # OpenDNS
```
-q mostra solo il riepilogo finale, perfetto per confronti veloci.

3. Verifica stabilità della rete nel tempo
```bash
# Ping continuo con 1 pacchetto/secondo (Ctrl+C per fermare)
ping google.com

# Ping continuo silenzioso, poi riepilogo
ping -q google.com
```
Lascialo girare per qualche minuto: se vedi packet loss intermittente
→ problema di rete instabile (tipico con VPN o WiFi scarso).

4. Ping con payload grande (simula traffico reale)
```bash
# Payload standard: 56 byte
ping -c 4 google.com

# Payload grande: 1400 byte (vicino alla MTU)
ping -c 4 -s 1400 google.com

# Payload massimo: 65507 byte
ping -c 4 -s 65507 google.com
```
Se il ping con payload piccolo funziona ma quello grande no
→ problema di MTU (molto comune con VPN!).

5. Diagnosi problema MTU su VPN
Il problema MTU è uno dei più comuni con le VPN.
La VPN aggiunge overhead al pacchetto, riducendo la MTU effettiva.

```bash
# Testa con dimensioni crescenti per trovare la MTU massima
for SIZE in 1400 1450 1472 1480 1490 1500; do
  if ping -c 1 -s $SIZE -M do 8.8.8.8 &>/dev/null; then
    echo "✅ Size $SIZE: OK"
  else
    echo "❌ Size $SIZE: FALLITO (troppo grande)"
  fi
done
```
Esercizi
🟢 Esercizio 1 — Connettività base
```bash
# 1. Ping verso IP locale (loopback)
ping -c 3 127.0.0.1

# 2. Ping verso DNS di Google
ping -c 3 8.8.8.8

# 3. Ping verso DNS di Cloudflare
ping -c 3 1.1.1.1

# 4. Ping verso un dominio
ping -c 3 google.com
```

Domande:

Qual è la latenza verso 127.0.0.1? Perché è così bassa?

Qual è più veloce tra 8.8.8.8 e 1.1.1.1?

L'IP risolto per google.com corrisponde a quello di dig +short google.com?

🟢 Esercizio 2 — Analisi riepilogo
```bash
# Invia 20 pacchetti in modalità silenziosa (solo riepilogo)
ping -c 20 -q google.com
ping -c 20 -q github.com
```
Domande:

Ci sono packet loss?

Qual è la deviazione standard (mdev)? Cosa indica?

Quale tra Google e GitHub ha latenza più stabile?

🟡 Esercizio 3 — Differenza IP vs DNS
```bash
# Step 1: risolvi l'IP di google.com
IP=$(dig +short google.com | head -1)
echo "IP di google.com: $IP"

# Step 2: ping all'IP diretto
ping -c 3 $IP

# Step 3: ping al nome
ping -c 3 google.com
```
Domande:

C'è differenza di latenza tra i due?

Quando è utile pingare direttamente l'IP invece del nome?

🟡 Esercizio 4 — Simula ping bloccato e usa alternativa
```bash
# Su alcuni host il ping è bloccato (firewall)
# Simula questo scenario con nc e curl

HOST="google.com"

# Test con ping
if ping -c 2 -W 2 "$HOST" &>/dev/null; then
  echo "PING: raggiungibile"
else
  echo "PING: bloccato o host giù"
  echo "→ Provo con nc..."
  if nc -zw2 "$HOST" 443 2>/dev/null; then
    echo "NC porta 443: APERTA (host è vivo!)"
  else
    echo "NC porta 443: CHIUSA"
  fi
fi
```
🔴 Esercizio 5 — Script di latency monitor
Crea latency-monitor.sh:

```bash
cat > latency-monitor.sh << 'SCRIPT'
#!/usr/bin/env bash
# Confronta latenza verso più host

HOSTS=("8.8.8.8" "1.1.1.1" "208.67.222.222" "9.9.9.9")
NAMES=("Google DNS" "Cloudflare" "OpenDNS" "Quad9")
COUNT=5

echo "=== Latency Monitor ($COUNT ping) ==="
echo ""
printf "%-20s %-20s %-10s %-10s %-10s\n" "HOST" "NOME" "MIN" "AVG" "LOSS"
printf "%-20s %-20s %-10s %-10s %-10s\n" "----" "----" "---" "---" "----"

for i in "${!HOSTS[@]}"; do
  HOST="${HOSTS[$i]}"
  NAME="${NAMES[$i]}"
  STATS=$(ping -c "$COUNT" -q "$HOST" 2>/dev/null | tail -2)
  LOSS=$(echo "$STATS" | grep -oP '\d+(?=% packet loss)')
  RTT=$(echo "$STATS" | grep -oP 'rtt.*= \K[\d.]+/[\d.]+')
  MIN=$(echo "$RTT" | cut -d'/' -f1)
  AVG=$(echo "$RTT" | cut -d'/' -f2)

  printf "%-20s %-20s %-10s %-10s %-10s\n" \
    "$HOST" "$NAME" "${MIN}ms" "${AVG}ms" "${LOSS}%"
done
SCRIPT
```
```bash
chmod +x latency-monitor.sh
./latency-monitor.sh
```