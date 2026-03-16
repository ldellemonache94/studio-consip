# 📥 wget — Download Affidabile e Ricorsivo

---

## Perché usare wget?

`wget` nasce per una cosa specifica: **scaricare file in modo affidabile**, anche
in condizioni di rete instabile.

La differenza fondamentale con `curl`:

- `curl` è ottimo per **interagire** con servizi HTTP (API, headers, autenticazione)
- `wget` è ottimo per **scaricare** file, riprendere download interrotti, fare mirror di siti

In ambito DevOps, `wget` si usa spesso negli **script di provisioning** e nei
**Dockerfile** per scaricare binari o archivi:

```dockerfile
RUN wget -q https://repo.esempio.com/tool-v1.2.3.tar.gz \
    && tar xzf tool-v1.2.3.tar.gz
```

## Quando usi wget (e non curl)
Situazione	Perché wget
Scaricare un file grande	Gestisce automaticamente il resume (-c)
Download in background	Flag -b nativo
Download ricorsivo di directory FTP/HTTP	Flag -r
Ambienti minimali (es. container Alpine)	wget è più leggero, spesso già installato
Script di provisioning semplici	Sintassi più semplice per download puri
VPN: come cambia wget
### Senza VPN
```bash
wget https://repo-pubblico.com/file.tar.gz
# → Connessione diretta a Internet
```
### Con VPN
```bash
wget https://nexus.interno.azienda.local/repository/file.jar
# → Traffico passa dalla VPN
# → Il repo interno è raggiungibile solo con VPN attiva
```
### Problemi tipici sotto VPN
```bash
# Proxy aziendale richiesto (alcune VPN aziendali usano un proxy HTTP)
wget https://repo.esempio.com/file.tar.gz
# → Errore di connessione

# Soluzione: configurare il proxy
wget -e use_proxy=yes \
     -e http_proxy=http://proxy.azienda.local:8080 \
     https://repo.esempio.com/file.tar.gz

# Oppure tramite variabile d'ambiente (più comoda)
export http_proxy=http://proxy.azienda.local:8080
export https_proxy=http://proxy.azienda.local:8080
wget https://repo.esempio.com/file.tar.gz

# Certificato SSL non valido (stessa situazione di curl)
wget --ca-certificate=/path/to/ca.crt https://repo.interno.azienda.local/file.tar.gz

# Ignora errori SSL (solo testing)
wget --no-check-certificate https://repo.interno.azienda.local/file.tar.gz
```
### Esempi pratici con spiegazione
1. Download semplice
```bash
wget https://example.com/file.tar.gz
wget salva il file nella directory corrente con il nome originale.
```
Mostra una barra di avanzamento con velocità e tempo stimato.

2. Salvare con nome custom
```bash
wget -O mio-nome-file.tar.gz https://example.com/release-1.0.0.tar.gz
-O (maiuscola) specifica il nome del file di output.
```
Equivalente di curl -o.

3. Riprendere un download interrotto
```bash
# Download interrotto a metà
wget https://example.com/file-grande.iso
# Ctrl+C

# Riprendi esattamente da dove si era fermato
wget -c https://example.com/file-grande.iso
```
Fondamentale per file grandi (ISO, tar.gz pesanti) su reti instabili o VPN.

4. Download silenzioso (per script)
```bash
# -q = quiet, nessun output
# -O - = manda l'output a stdout invece di salvarlo su file
wget -qO- https://example.com
wget -qO- https://httpbin.org/get | jq .
wget -qO- è l'equivalente di curl -s per leggere il contenuto di una URL.
```
5. Verificare che una URL sia raggiungibile senza scaricarla
```bash
# --spider = simula il download ma non scarica niente
# -q = silenzioso
# --server-response = mostra gli header HTTP
wget --spider -q --server-response https://example.com 2>&1 | head -10
```
Usa questo quando vuoi verificare la raggiungibilità senza consumare banda.

6. Download in Dockerfile (pattern comune)
```bash
# Pattern tipico nei Dockerfile per scaricare binari
RUN wget -q --show-progress \
    https://storage.googleapis.com/kubernetes-release/release/v1.29.0/bin/linux/amd64/kubectl \
    -O /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl
```
Esercizi
🟢 Esercizio 1 — Download base
```bash
# 1. Scarica una pagina web
wget https://example.com

# 2. Guarda cosa è stato scaricato
ls -lh index.html
cat index.html | head -20

# 3. Scarica e salva con nome custom
wget -O pagina-test.html https://example.com

# 4. Pulisci
rm index.html pagina-test.html
```
Domande:

Che dimensione ha il file scaricato?

Cosa contiene?

🟢 Esercizio 2 — Verifica raggiungibilità con --spider
```bash
# Testa questi URL senza scaricarli
wget --spider -q --server-response https://google.com 2>&1 | grep "HTTP/"
wget --spider -q --server-response https://httpbin.org/status/404 2>&1 | grep "HTTP/"
wget --spider -q --server-response https://httpbin.org/status/500 2>&1 | grep "HTTP/"
```
Domande:

Quali codici HTTP vedi?

Come useresti questo in uno script per verificare che un servizio sia up?

🟡 Esercizio 3 — wget come curl: leggere risposte API
```bash
# wget può anche fare chiamate HTTP e leggere le risposte
wget -qO- https://httpbin.org/get
wget -qO- https://httpbin.org/ip

# Con header custom (meno comodo di curl ma possibile)
wget -qO- --header="Authorization: Bearer TOKEN" \
  https://httpbin.org/bearer
```
Domande:

Che IP mostra httpbin.org/ip?

In che formato è la risposta?

🟡 Esercizio 4 — Script: download con retry
Crea safe-download.sh:

```bash
cat > safe-download.sh << 'SCRIPT'
#!/usr/bin/env bash
# Download con retry automatico e verifica

URL=$1
OUTPUT=$2
MAX_RETRIES=3

if [ -z "$URL" ]; then
  echo "Uso: $0 <URL> [nome-output]"
  exit 1
fi

OUTPUT=${OUTPUT:-$(basename "$URL")}

echo "Download: $URL"
echo "Output:   $OUTPUT"
echo "Retry:    max $MAX_RETRIES tentativi"
echo ""

wget \
  --tries=$MAX_RETRIES \
  --timeout=30 \
  --wait=5 \
  --continue \
  --show-progress \
  -O "$OUTPUT" \
  "$URL"

if [ $? -eq 0 ]; then
  SIZE=$(du -sh "$OUTPUT" | cut -f1)
  echo ""
  echo "✅ Download completato: $OUTPUT ($SIZE)"
else
  echo ""
  echo "❌ Download fallito dopo $MAX_RETRIES tentativi"
  exit 1
fi
SCRIPT
```

```bash
chmod +x safe-download.sh
./safe-download.sh https://example.com test-page.html
```