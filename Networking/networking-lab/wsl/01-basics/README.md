# ATTENZIONE AI COMANDI CHE LANCIATE NON MI PRENDO RESPONSABILITA' :)
***
# 🟢 01 - Comandi fondamentali di networking

**Livello:** Base 
**Strumenti:** `ping`, `curl`, `wget`, `dig`, `nslookup`, `ip`, `ss`  
**Dove:** Shell WSL/Linux

---

## Esercizio 1 — Connettività di base con ping

```bash
# 1. Pinga un IP pubblico (no DNS)
ping -c 4 8.8.8.8

# 2. Pinga un dominio (serve DNS)
ping -c 4 google.com

# 3. Pinga un host locale
ping -c 2 127.0.0.1

# 4. Ping silenzioso con solo il riepilogo
ping -q -c 10 8.8.8.8
```

Ecco il testo **formattato correttamente in Markdown**:

### Domande

- Qual è la **latenza** verso `8.8.8.8`?
- Cosa cambia tra pingare `8.8.8.8` e `google.com`?
- Se `ping google.com` fallisce ma `ping 8.8.8.8` funziona, qual è il problema?

<details>
<summary>💡 Risposta</summary>

Se l'IP funziona ma il nome no → **problema di DNS**.  
Controlla `/etc/resolv.conf` e il **nameserver configurato**.

</details>

---

# Esercizio 2 — DNS con nslookup e dig

```bash
# nslookup base
nslookup google.com
nslookup github.com

# Risoluzione inversa (IP → nome)
nslookup 8.8.8.8

# dig - solo risultato
dig +short google.com

# dig - record specifici
dig +short A google.com
dig +short AAAA google.com
dig +short MX gmail.com
dig +short NS google.com

# Usa un resolver specifico
dig @1.1.1.1 google.com
dig @8.8.8.8 google.com
```

### Domande

* Quanti **IP** ha `google.com`?
* Quali **MX server** usa `gmail.com` e con quale **priorità**?
* C'è differenza di risposta tra il resolver `1.1.1.1` e `8.8.8.8`?

---

# Esercizio 3 — curl: richieste HTTP

```bash
# GET base
curl https://example.com

# Solo il codice HTTP
curl -s -o /dev/null -w "%{http_code}\n" https://google.com

# Mostra header di risposta
curl -I https://example.com

# Verbose: tutto il dettaglio
curl -v https://example.com 2>&1 | head -40

# POST con JSON
curl -X POST https://httpbin.org/post \
  -H "Content-Type: application/json" \
  -d '{"nome": "Leonardo", "team": "DevOps"}'

# Segui redirect
curl -L https://google.com -o /dev/null -w "%{http_code}\n"

# Timeout
curl --max-time 3 https://httpbin.org/delay/10 || echo "Timeout!"
```

### Domande

* Qual è il **codice HTTP** di `https://google.com` senza `-L`?
* Quanti **redirect** fa prima di arrivare alla pagina?
* Cosa contiene la risposta JSON di `httpbin.org/post`?

---

# Esercizio 4 — wget: download di file

```bash
# Download semplice
wget https://example.com

# Salvare con nome custom
wget -O mia-pagina.html https://example.com

# Download silenzioso
wget -q https://example.com -O /dev/null

# Riprendere un download interrotto
wget -c https://example.com/file.tar.gz

# Mostrare solo gli header (senza scaricare il contenuto)
wget --server-response --spider https://example.com 2>&1 | head -20
```

### Domande

* Qual è la differenza tra `curl -O` e `wget`?
* Quando useresti **wget** invece di **curl**?

---

# Esercizio 5 — Interfacce di rete e routing

```bash
# Mostra interfacce e IP
ip addr show
ip a   # forma breve

# Mostra solo l'interfaccia eth0
ip addr show eth0

# Mostra la tabella di routing
ip route show
ip r   # forma breve

# Mostra la ARP table
ip neigh show

# Statistiche sull'interfaccia
ip -s link show eth0
```

### Domande

* Qual è il tuo **IP privato su WSL**?
* Qual è il **gateway predefinito**?
* Quante **interfacce di rete** vedi? (es. `lo`, `eth0`)

---

# Esercizio 6 — Stato connessioni con ss

```bash
# Tutte le connessioni TCP attive
ss -tn

# Porte in ascolto con processo associato
ss -tlnp

# Porte UDP in ascolto
ss -ulnp

# Tutto (TCP + UDP, ascolto + connesse)
ss -tunap

# Filtrare per porta 80
ss -tn sport = :80 or dport = :80
```

### Domande

* Ci sono **servizi in ascolto** sul tuo WSL?
* Quali **porte**? Quali **processi**?
* Quante connessioni TCP sono **ESTABLISHED**?
