# 🌐 curl — Il Tuo Migliore Amico per il Debug HTTP

---

## Perché usare curl?

`curl` è lo strumento più importante per testare **tutto ciò che riguarda HTTP/HTTPS**.

La sua forza sta nel fatto che **simula esattamente quello che farebbe un'applicazione**:
costruisce una richiesta HTTP, la manda, riceve la risposta e te la mostra.

Quando un servizio "non funziona", spesso il primo dubbio è:
> "Sarà un problema di rete? Di autenticazione? Di SSL? Di routing?"

Con `curl -v` hai **tutto in una sola riga di comando**: vedi la risoluzione DNS,
la connessione TCP, l'handshake TLS, gli header HTTP inviati e ricevuti, il body.
Nessun altro tool ti dà tutte queste informazioni insieme.

---

## Quando usi curl (e non altri tool)

| Situazione | Perché curl |
|---|---|
| Testare un'API REST | Puoi mandare GET/POST/PUT/DELETE con body e header custom |
| Debug SSL/TLS | Mostra il certificato, la catena, gli errori |
| Verificare redirect | Con `-L` segue i redirect, con `-v` li mostra uno per uno |
| Testare autenticazione | Supporta Basic, Bearer token, mTLS |
| Misurare le performance HTTP | Con `-w` stampa tempi DNS, TCP, TLS, trasferimento |
| Testare da dentro un Pod K8s | Disponibile in quasi tutte le immagini, o con netshoot |
| Verificare header specifici | Puoi settare qualsiasi header e vedere cosa risponde il server |

---

## VPN: come cambia il comportamento di curl

### Senza VPN
```bash
curl https://api.servizio-pubblico.com
# → Risolve il DNS pubblico, connessione diretta via Internet
```
Con VPN aziendale
```bash
curl https://api.interno.azienda.local
# → Il DNS aziendale risolve il nome interno
# → Il traffico passa dal VPN tunnel
# → Il server vede come IP sorgente quello del VPN gateway
Problemi tipici sotto VPN
# Certificato SSL non valido (CA aziendale non trusted)
curl https://api.interno.azienda.local
# curl: (60) SSL certificate problem: unable to get local issuer certificate

# Soluzione 1: specificare il bundle CA aziendale
curl --cacert /path/to/azienda-ca.crt https://api.interno.azienda.local

# Soluzione 2 (solo testing, MAI in produzione)
curl -k https://api.interno.azienda.local

# DNS non risolve (VPN non ancora connessa o resolver sbagliato)
curl https://api.interno.azienda.local
# curl: (6) Could not resolve host: api.interno.azienda.local
```

Split tunneling e curl
Con split tunneling, alcune rotte passano per VPN e altre no.
Per capire quale percorso fa una richiesta:

```bash
# Vedi l'IP a cui si connette curl
curl -v https://api.esempio.com 2>&1 | grep "Connected to"
# → Connected to api.esempio.com (10.0.1.50) port 443

# Se l'IP è privato (10.x, 172.x, 192.168.x) → passa per VPN
# Se l'IP è pubblico → va diretto
```
Anatomia di curl -v (leggi l'output)
```bash
curl -v https://httpbin.org/get
Output commentato:
```

*   Trying 54.208.105.16:443...       ← risoluzione DNS + tentativo TCP
* Connected to httpbin.org (54.208.105.16) port 443
* SSL connection using TLSv1.3        ← handshake TLS riuscito
* Server certificate: httpbin.org     ← dettagli certificato

> GET /get HTTP/1.1                   ← → cosa MANDI al server
> Host: httpbin.org
> User-Agent: curl/7.88.1
> Accept: */*
>
< HTTP/1.1 200 OK                     ← ← cosa RICEVI dal server
< Content-Type: application/json
< Content-Length: 312
<
{ ... json body ... }                 ← body della risposta
Esempi pratici con spiegazione
1. Verifica se un servizio risponde (il più usato in assoluto)
```bash
curl -s -o /dev/null -w "%{http_code}" https://mio-servizio.com
```
-s → silenzioso, niente output di progresso

-o /dev/null → scarta il body (non ci interessa)

-w "%{http_code}" → stampa solo il codice HTTP (es. 200, 404, 503)

Uso tipico in uno script di health check:

```bash
CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 https://mio-servizio.com)
if [ "$CODE" -eq 200 ]; then
  echo "OK"
else
  echo "KO: $CODE"
fi
```
2. Debug completo di una chiamata API
```bash
curl -v \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer IL_MIO_TOKEN" \
  -d '{"key": "value"}' \
  https://api.esempio.com/endpoint
```
Usa questo quando un'API non risponde come ti aspetti: vedi esattamente
cosa mandi e cosa ricevi, header inclusi.

3. Misura i tempi di ogni fase
```bash
curl -s -o /dev/null -w "
DNS lookup:        %{time_namelookup}s
TCP connect:       %{time_connect}s
TLS handshake:     %{time_appconnect}s
First byte:        %{time_starttransfer}s
Total:             %{time_total}s
" https://google.com
```
Questo è fondamentale per capire dove perdi tempo:

DNS lento → problema di resolver

TCP lento → problema di rete/routing

TLS lento → problema di certificati o negoziazione

First byte lento → l'applicazione è lenta a rispondere

4. Testa un endpoint Kubernetes dall'interno di un Pod
```bash
# Entra nel Pod
kubectl exec -it <pod-name> -n <namespace> -- bash

# Chiama un Service interno
curl http://nome-service.namespace.svc.cluster.local/health

# Chiama l'API server di Kubernetes
curl -k \
  -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  https://kubernetes.default.svc/api/v1/namespaces
```
5. Debug certificato SSL
```bash
# Mostra dettagli del certificato
curl -v https://example.com 2>&1 | grep -A5 "Server certificate"

# Testa con una CA custom
curl --cacert /etc/ssl/certs/my-ca.crt https://internal.service.local

# Ignora errori SSL (SOLO testing, mai in produzione)
curl -k https://internal.service.local

# Verifica la catena di certificati completa
curl -v --cacert /dev/null https://example.com 2>&1 | grep -E "SSL|certificate|issuer"
```
6. Testa connettività con curl quando ping è bloccato
Quando sei sotto VPN o in ambienti aziendali, il ping ICMP è spesso bloccato
dai firewall. Ma HTTP no. Quindi:

```bash
# ping bloccato → usi curl per verificare che l'host sia raggiungibile
curl -s -o /dev/null -w "%{http_code}" --max-time 3 http://host-interno

# Se ricevi anche solo un "Connection refused" → l'host è raggiungibile,
# ma quella porta è chiusa. Il routing funziona!
curl http://host-interno:9999 2>&1
# curl: (7) Failed to connect to host-interno port 9999: Connection refused
# → BUONA notizia: l'host risponde! La porta 9999 è semplicemente chiusa.
```
Esercizi
🟢 Esercizio 1 — Codici HTTP
```bash
# Ottieni il codice HTTP di questi URL e spiega cosa significa ognuno
curl -s -o /dev/null -w "%{http_code}\n" https://google.com
curl -s -o /dev/null -w "%{http_code}\n" https://httpbin.org/status/404
curl -s -o /dev/null -w "%{http_code}\n" https://httpbin.org/status/500
curl -s -o /dev/null -w "%{http_code}\n" https://httpbin.org/redirect/3
```
Domande:

Cosa significa ciascun codice?

Con il redirect: ottieni 302 o 200? Perché? Cosa cambia con -L?

🟢 Esercizio 2 — Header e body
```bash
# Manda una POST con JSON e osserva la risposta
curl -X POST https://httpbin.org/post \
  -H "Content-Type: application/json" \
  -H "X-Custom-Header: ciao-team" \
  -d '{"ambiente": "test", "tool": "curl"}'
```
Domande:

Dove vedi il tuo X-Custom-Header nella risposta?

Dove vedi il tuo body JSON?

Che IP ha usato httpbin.org per vederti? (campo origin)

🟡 Esercizio 3 — Misura le performance
```bash
curl -s -o /dev/null -w "DNS:%{time_namelookup}s TCP:%{time_connect}s TLS:%{time_appconnect}s TOTAL:%{time_total}s\n" https://google.com
curl -s -o /dev/null -w "DNS:%{time_namelookup}s TCP:%{time_connect}s TLS:%{time_appconnect}s TOTAL:%{time_total}s\n" https://github.com
curl -s -o /dev/null -w "DNS:%{time_namelookup}s TCP:%{time_connect}s TLS:%{time_appconnect}s TOTAL:%{time_total}s\n" https://cloudflare.com
```
Domande:

Quale servizio è più veloce?

Quale fase è più lenta per ciascuno?

Se il tempo DNS è > 1s, qual è il problema?

🟡 Esercizio 4 — Simula un problema di autenticazione
```bash
# Chiamata senza autenticazione
curl -v https://httpbin.org/basic-auth/utente/password123

# Con autenticazione Basic corretta
curl -v -u utente:password123 https://httpbin.org/basic-auth/utente/password123

# Con password sbagliata
curl -v -u utente:passwordsbagliata https://httpbin.org/basic-auth/utente/password123
```
Domande:

Cosa risponde il server senza autenticazione?

Cosa cambia nell'header Authorization tra le tre chiamate?

Qual è il codice HTTP per "non autorizzato"?

🔴 Esercizio 5 — Script di monitoring HTTP
Crea http-monitor.sh:

```bash
cat > http-monitor.sh << 'SCRIPT'

#!/usr/bin/env bash
# Monitora una lista di endpoint ogni N secondi

ENDPOINTS=(
  "https://google.com"
  "https://github.com"
  "https://httpbin.org/status/200"
  "https://httpbin.org/status/503"
)
INTERVAL=10

while true; do
  clear
  echo "=== HTTP Monitor — $(date '+%Y-%m-%d %H:%M:%S') ==="
  echo ""
  printf "%-45s %-8s %-10s\n" "ENDPOINT" "CODE" "LATENZA"
  printf "%-45s %-8s %-10s\n" "--------" "----" "-------"

  for URL in "${ENDPOINTS[@]}"; do
    RESULT=$(curl -s -o /dev/null \
      -w "%{http_code} %{time_total}" \
      --max-time 5 "$URL" 2>/dev/null)
    CODE=$(echo "$RESULT" | awk '{print $1}')
    TIME=$(echo "$RESULT" | awk '{printf "%.3fs", $2}')

    if [[ "$CODE" =~ ^ ]]; then
      STATUS="✅ $CODE"
    else
      STATUS="❌ $CODE"
    fi
    printf "%-45s %-8s %-10s\n" "$URL" "$STATUS" "$TIME"
  done

  echo ""
  echo "Prossimo check in ${INTERVAL}s... (Ctrl+C per uscire)"
  sleep "$INTERVAL"
done
SCRIPT
```

```bash
chmod +x http-monitor.sh
./http-monitor.sh
```