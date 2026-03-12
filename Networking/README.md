***

# 🌐 Networking da Riga di Comando — Guida Completa

> Guida pratica ai comandi fondamentali di rete per sviluppatori e DevOps Engineer.  
> Ogni comando è spiegato con sintassi, opzioni principali ed esempi reali.

***

## Indice

- [Concetti Base](#concetti-base)
- [curl](#curl)
- [wget](#wget)
- [ping](#ping)
- [traceroute / tracepath](#traceroute--tracepath)
- [nslookup e dig](#nslookup-e-dig)
- [netstat e ss](#netstat-e-ss)
- [nmap](#nmap)
- [telnet e nc (netcat)](#telnet-e-nc-netcat)
- [ip e ifconfig](#ip-e-ifconfig)
- [iptables e nftables](#iptables-e-nftables)
- [ssh](#ssh)
- [scp e rsync](#scp-e-rsync)
- [tcpdump](#tcpdump)
- [host e whois](#host-e-whois)
- [Esercizi Pratici](#esercizi-pratici)

***

## Concetti Base

Prima di iniziare con i comandi, è utile avere chiari alcuni concetti fondamentali.

**IP Address**: Identificatore univoco di un host in rete. Può essere IPv4 (es. `192.168.1.1`) o IPv6 (es. `fe80::1`).

**Porta**: Numero che identifica un processo/servizio su un host. Le porte well-known vanno da 0 a 1023 (es. HTTP=80, HTTPS=443, SSH=22).

**DNS (Domain Name System)**: Sistema che traduce i nomi di dominio (es. `google.com`) in indirizzi IP.

**Protocolli principali**:
- `TCP` — affidabile, orientato alla connessione (HTTP, SSH, FTP)
- `UDP` — veloce, non affidabile (DNS, streaming, gaming)
- `ICMP` — messaggi di controllo/diagnostica (usato da `ping`)

***

## curl

`curl` (Client URL) è lo strumento più potente per trasferire dati via protocolli come HTTP, HTTPS, FTP, SFTP e molti altri. È essenziale in DevOps per testare API, endpoint e servizi.

### Sintassi base

```bash
curl [opzioni] <URL>
```

### Opzioni principali

| Opzione | Descrizione |
|---|---|
| `-X METHOD` | Specifica il metodo HTTP (GET, POST, PUT, DELETE, PATCH) |
| `-H "Header: Value"` | Aggiunge un header alla richiesta |
| `-d "data"` | Invia dati nel body (default: POST) |
| `-o file` | Salva l'output su file |
| `-O` | Salva il file con il nome originale |
| `-L` | Segue i redirect automaticamente |
| `-I` | Mostra solo gli header della risposta (HEAD request) |
| `-v` | Verbose: mostra il dettaglio della connessione |
| `-s` | Silent: sopprime output di progresso |
| `-k` | Ignora errori SSL (⚠️ solo per testing!) |
| `-u user:pass` | Autenticazione Basic |
| `--max-time N` | Timeout in secondi |
| `-w "%{http_code}"` | Stampa il codice di stato HTTP |

### Esempi pratici

```bash
# GET semplice
curl https://api.github.com

# POST con JSON body
curl -X POST https://api.esempio.com/users \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN" \
  -d '{"name": "Leonardo", "role": "DevOps"}'

# Salvare un file
curl -o output.html https://example.com

# Seguire redirect e vedere gli header
curl -LI https://example.com

# Testare un endpoint Kubernetes (dall'interno del cluster)
curl http://my-service.namespace.svc.cluster.local:8080/health

# Verificare solo il codice HTTP
curl -s -o /dev/null -w "%{http_code}" https://example.com

# Upload di un file con multipart/form-data
curl -F "file=@/path/to/file.txt" https://api.esempio.com/upload

# Usare un proxy
curl -x http://proxy.esempio.com:8080 https://target.com

# Inviare richiesta con timeout
curl --max-time 5 https://slow-service.com
```

### curl in DevOps/Kubernetes

```bash
# Health check di un pod (dall'interno)
curl http://localhost:8080/actuator/health

# Chiamata a Kubernetes API Server
curl -k -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  https://kubernetes.default.svc/api/v1/namespaces

# Testare un Ingress con Host header specifico
curl -H "Host: myapp.esempio.com" http://<INGRESS_IP>/api/health
```

***

## wget

`wget` è pensato principalmente per il **download ricorsivo** di file e siti web. Meno flessibile di `curl` per le API, ma eccellente per scaricare risorse.

### Sintassi base

```bash
wget [opzioni] <URL>
```

### Opzioni principali

| Opzione | Descrizione |
|---|---|
| `-O file` | Salva con nome specificato |
| `-P directory` | Salva in una directory specifica |
| `-q` | Quiet mode |
| `-r` | Download ricorsivo |
| `-np` | Non risalire alla directory padre (con `-r`) |
| `--no-check-certificate` | Ignora errori SSL |
| `-c` | Riprendi download interrotto |
| `--limit-rate=RATE` | Limita la velocità (es. `--limit-rate=1m`) |
| `-b` | Background download |
| `--tries=N` | Numero di tentativi in caso di errore |
| `--mirror` | Mirror completo di un sito |

### Esempi pratici

```bash
# Download semplice
wget https://example.com/file.tar.gz

# Salvare con nome custom
wget -O mio-file.tar.gz https://example.com/release-v1.0.tar.gz

# Download in background
wget -b https://example.com/large-file.iso

# Riprendere un download interrotto
wget -c https://example.com/large-file.iso

# Download ricorsivo di un sito (mirror)
wget --mirror --convert-links --adjust-extension \
  --page-requisites --no-parent https://esempio.com

# Scaricare un file con autenticazione
wget --user=admin --password=secret https://repo.esempio.com/file.rpm
```

### curl vs wget — Quando usare quale?

- **curl**: testing API, invio di dati, scripting avanzato, supporto protocolli multipli
- **wget**: download di file, mirroring di siti, download ricorsivi, resume di download

***

## ping

`ping` usa il protocollo **ICMP Echo Request/Reply** per verificare la raggiungibilità di un host e misurare la latenza (RTT - Round Trip Time).

### Sintassi base

```bash
ping [opzioni] <host>
```

### Opzioni principali

| Opzione | Descrizione |
|---|---|
| `-c N` | Invia N pacchetti poi si ferma |
| `-i N` | Intervallo tra i pacchetti (secondi) |
| `-s N` | Dimensione del payload in byte |
| `-t N` | TTL (Time To Live) |
| `-W N` | Timeout attesa risposta (secondi) |
| `-q` | Quiet: mostra solo il riepilogo finale |
| `-f` | Flood ping (⚠️ solo con permessi di root) |

### Esempi pratici

```bash
# Ping base (Ctrl+C per fermare)
ping google.com

# Inviare solo 4 pacchetti
ping -c 4 8.8.8.8

# Ping con payload più grande (simula traffico reale)
ping -s 1472 google.com

# Ping silenzioso con riepilogo
ping -q -c 10 192.168.1.1

# Verificare latenza verso un nodo Kubernetes
ping -c 5 10.0.0.1
```

### Interpretare l'output

```
PING google.com (142.250.180.46): 56 data bytes
64 bytes from 142.250.180.46: icmp_seq=0 ttl=117 time=12.345 ms

--- google.com ping statistics ---
4 packets transmitted, 4 received, 0% packet loss
rtt min/avg/max/mdev = 11.2/12.3/13.1/0.7 ms
```

- **packet loss > 0%** → possibile problema di rete o congestione
- **RTT alto** → latenza elevata
- **TTL** → indica quanti hop ha attraversato il pacchetto

***

## traceroute / tracepath

`traceroute` mostra il **percorso** che i pacchetti compiono dalla sorgente alla destinazione, hop per hop. Fondamentale per diagnosticare dove si verifica un problema di rete.

### Sintassi base

```bash
traceroute [opzioni] <host>
tracepath <host>           # alternativa senza privilegi root
```

### Opzioni principali

| Opzione | Descrizione |
|---|---|
| `-n` | Non risolvere i nomi DNS (più veloce) |
| `-m N` | Massimo numero di hop (default: 30) |
| `-w N` | Timeout per ogni risposta |
| `-I` | Usa ICMP invece di UDP |
| `-T` | Usa TCP (porta 80, utile quando ICMP è bloccato) |
| `-p PORT` | Porta destinazione |

### Esempi pratici

```bash
# Traceroute base
traceroute google.com

# Senza risoluzione DNS (più veloce)
traceroute -n google.com

# Usare TCP (spesso non bloccato dai firewall)
traceroute -T -p 443 google.com

# Limitare a 15 hop
traceroute -m 15 8.8.8.8

# tracepath (non richiede root)
tracepath google.com
```

### Interpretare l'output

```
traceroute to google.com (142.250.180.46)
 1  192.168.1.1 (192.168.1.1)    1.234 ms
 2  10.0.0.1 (10.0.0.1)          5.678 ms
 3  * * *                         (hop non risponde)
 4  209.85.252.100               12.345 ms
```

- `* * *` → il router non risponde a ICMP (firewall o configurazione) ma non significa necessariamente un problema
- Latenza che cresce linearmente → normale
- Latenza che schizza improvvisamente → possibile collo di bottiglia

***

## nslookup e dig

Entrambi servono per interrogare i server DNS. `dig` è molto più potente e dettagliato, preferito in ambito professionale.

### nslookup

```bash
# Risoluzione base
nslookup google.com

# Risoluzione inversa (IP → hostname)
nslookup 8.8.8.8

# Usare un DNS specifico
nslookup google.com 1.1.1.1

# Cercare record MX (mail)
nslookup -type=MX gmail.com
```

### dig

```bash
# Query base
dig google.com

# Solo la risposta (senza metadata)
dig +short google.com

# Record specifici
dig google.com A          # IPv4
dig google.com AAAA       # IPv6
dig google.com MX         # Mail server
dig google.com NS         # Name server
dig google.com TXT        # Record TXT (SPF, DKIM, ecc.)
dig google.com CNAME      # Alias

# Usare un resolver specifico
dig @8.8.8.8 google.com

# Risoluzione inversa
dig -x 8.8.8.8

# Tracciare la catena DNS completa
dig +trace google.com

# Risposta compatta
dig +noall +answer google.com
```

### Esempi in contesto DevOps

```bash
# Verificare la propagazione DNS di un nuovo dominio
dig +trace myapp.esempio.com

# Verificare i record di un servizio Kubernetes (CoreDNS)
dig @<CoreDNS-IP> my-service.namespace.svc.cluster.local

# Controllare i record TXT per verifica dominio
dig TXT _acme-challenge.esempio.com
```

***

## netstat e ss

`netstat` è lo strumento classico per visualizzare connessioni di rete, porte in ascolto e tabelle di routing. Nei sistemi moderni è stato sostituito da `ss` (socket statistics), più veloce e completo.

> ⚠️ Su molte distribuzioni Linux moderne `netstat` non è installato di default. Usa `ss`.

### ss — Opzioni principali

| Opzione | Descrizione |
|---|---|
| `-t` | Mostra socket TCP |
| `-u` | Mostra socket UDP |
| `-l` | Mostra solo porte in LISTEN |
| `-n` | Numerico (non risolvere nomi) |
| `-p` | Mostra il processo associato |
| `-a` | Tutti i socket (inclusi quelli non connessi) |
| `-r` | Tabella di routing |
| `-s` | Statistiche aggregate |

### Esempi pratici

```bash
# Tutte le connessioni TCP attive
ss -tn

# Porte in ascolto (con processo associato)
ss -tlnp

# Porte UDP in ascolto
ss -ulnp

# Filtrare per porta specifica
ss -tnp sport = :8080

# Statistiche generali di rete
ss -s

# Connessioni verso un IP specifico
ss -tn dst 192.168.1.100

# Equivalente netstat
netstat -tulnp    # porte in ascolto
netstat -an       # tutte le connessioni
netstat -rn       # tabella di routing
```

***

## nmap

`nmap` (Network Mapper) è il tool più completo per **port scanning** e **discovery di rete**. Indispensabile in ambito DevSecOps per verificare l'esposizione dei servizi.

> ⚠️ Usare `nmap` su reti o host senza autorizzazione è illegale. Usarlo solo su infrastrutture proprie o con permesso esplicito.

### Sintassi base

```bash
nmap [opzioni] <target>
```

### Esempi pratici

```bash
# Scan delle porte più comuni
nmap 192.168.1.1

# Scan di tutte le 65535 porte
nmap -p- 192.168.1.1

# Scan di porte specifiche
nmap -p 22,80,443,8080 192.168.1.1

# Rilevare il sistema operativo e versioni servizi
nmap -A 192.168.1.1

# Scan di una subnet intera
nmap 192.168.1.0/24

# Scan veloce (porte comuni)
nmap -F 192.168.1.1

# Scan silenzioso (SYN scan, richiede root)
nmap -sS 192.168.1.1

# Rilevare versioni dei servizi
nmap -sV 192.168.1.1

# Ping scan (solo discovery, no port scan)
nmap -sn 192.168.1.0/24

# Output in formato XML (per automazione)
nmap -oX output.xml 192.168.1.1

# Scan UDP
nmap -sU -p 53,123,161 192.168.1.1
```

### nmap in DevSecOps

```bash
# Verificare quali porte sono esposte su un nodo Kubernetes
nmap -p- <NODE_IP>

# Scoprire tutti gli host attivi in una rete
nmap -sn 10.0.0.0/16

# Verificare se una porta è raggiungibile (alternativa veloce a telnet)
nmap -p 5432 db-server.interno
```

***

## telnet e nc (netcat)

### telnet

`telnet` è un protocollo legacy ma ancora molto usato per **testare la connettività TCP** su una specifica porta.

```bash
# Verificare se una porta è aperta
telnet hostname 80
telnet 192.168.1.100 5432  # PostgreSQL
telnet redis-host 6379     # Redis

# Se la connessione si apre → la porta è raggiungibile
# Se "Connection refused" → porta chiusa o servizio non attivo
# Se timeout → firewall o host irraggiungibile
```

### nc (netcat)

`nc` è molto più versatile di `telnet`. È il "coltellino svizzero" del networking.

```bash
# Test di connettività TCP (come telnet)
nc -zv hostname 80

# Test di connettività UDP
nc -zvu hostname 53

# Scan di un range di porte
nc -zv 192.168.1.1 20-100

# Creare un server TCP di ascolto (per testing)
nc -l 9999

# Connettersi al server appena creato (su altro terminale)
nc localhost 9999

# Trasferire un file via rete
# Sul ricevente:
nc -l 9999 > file_ricevuto.txt
# Sul mittente:
nc hostname 9999 < file_da_inviare.txt

# Chat semplice tra due host
nc -l 5555         # host A
nc hostA 5555      # host B

# Banner grabbing (identificare servizi)
echo "" | nc -w 1 hostname 22
```

***

## ip e ifconfig

### ip (moderno, raccomandato)

Il comando `ip` è il sostituto moderno di `ifconfig`, `route` e `arp`.

```bash
# Mostrare tutte le interfacce di rete
ip addr show
ip a        # forma abbreviata

# Mostrare info di una interfaccia specifica
ip addr show eth0

# Aggiungere un indirizzo IP
ip addr add 192.168.1.100/24 dev eth0

# Rimuovere un indirizzo IP
ip addr del 192.168.1.100/24 dev eth0

# Attivare/disattivare un'interfaccia
ip link set eth0 up
ip link set eth0 down

# Mostrare la tabella di routing
ip route show
ip r        # forma abbreviata

# Aggiungere una route
ip route add 10.0.0.0/8 via 192.168.1.1

# Aggiungere la route di default (gateway)
ip route add default via 192.168.1.1

# Mostrare la ARP table (cache)
ip neigh show
ip n

# Mostrare statistiche di interfaccia
ip -s link show eth0
```

### ifconfig (legacy)

```bash
# Mostrare tutte le interfacce
ifconfig -a

# Info di un'interfaccia specifica
ifconfig eth0

# Assegnare un IP
ifconfig eth0 192.168.1.100 netmask 255.255.255.0

# Attivare/disattivare
ifconfig eth0 up
ifconfig eth0 down
```

***

## iptables e nftables

`iptables` gestisce il firewall del kernel Linux. Nei sistemi più recenti si usa `nftables`, ma `iptables` rimane lo standard de facto.

```bash
# Visualizzare le regole attive
iptables -L -n -v
iptables -L -n -v --line-numbers   # con numeri di riga

# Visualizzare regole NAT
iptables -t nat -L -n -v

# Permettere traffico in ingresso su porta 80
iptables -A INPUT -p tcp --dport 80 -j ACCEPT

# Bloccare un IP specifico
iptables -A INPUT -s 192.168.1.100 -j DROP

# Bloccare tutto il traffico in ingresso tranne SSH
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -P INPUT DROP

# Eliminare una regola specifica (per numero di riga)
iptables -D INPUT 3

# Svuotare tutte le regole
iptables -F

# Salvare le regole (Debian/Ubuntu)
iptables-save > /etc/iptables/rules.v4

# Masquerade (NAT per routing)
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

***

## ssh

`ssh` (Secure Shell) è il protocollo standard per accedere in modo sicuro a sistemi remoti.

```bash
# Connessione base
ssh user@hostname
ssh user@192.168.1.100

# Usare una chiave privata specifica
ssh -i ~/.ssh/mia_chiave.pem user@hostname

# Porta custom
ssh -p 2222 user@hostname

# Eseguire un comando remoto senza shell interattiva
ssh user@hostname "df -h"
ssh user@hostname "kubectl get pods -A"

# Tunnel SSH (port forwarding locale)
# Accedi a un servizio remoto come se fosse locale
ssh -L 8080:localhost:80 user@remote-server
# Ora http://localhost:8080 → porta 80 del server remoto

# Tunnel SSH inverso (esponi una porta locale su server remoto)
ssh -R 9090:localhost:3000 user@remote-server

# SOCKS proxy (tunnel dinamico)
ssh -D 1080 user@remote-server

# Connessione con keep-alive
ssh -o ServerAliveInterval=60 user@hostname

# Generare una coppia di chiavi SSH
ssh-keygen -t ed25519 -C "leonardo@esempio.com"

# Copiare la chiave pubblica su un server remoto
ssh-copy-id user@hostname

# Configurazione avanzata (~/.ssh/config)
cat ~/.ssh/config
# Host myserver
#   HostName 192.168.1.100
#   User leonardo
#   IdentityFile ~/.ssh/mykey
#   Port 2222
```

***

## scp e rsync

### scp (Secure Copy)

```bash
# Copiare un file locale su server remoto
scp /path/locale/file.txt user@hostname:/path/remoto/

# Copiare dal server remoto in locale
scp user@hostname:/path/remoto/file.txt /path/locale/

# Copiare una directory (ricorsivo)
scp -r /path/locale/directory/ user@hostname:/path/remoto/

# Usare chiave specifica
scp -i ~/.ssh/mykey.pem file.txt user@hostname:/tmp/
```

### rsync

`rsync` è più efficiente di `scp` perché trasferisce solo le differenze (delta).

```bash
# Sincronizzare directory locale su server remoto
rsync -avz /path/locale/ user@hostname:/path/remoto/

# Con eliminazione file non presenti nella sorgente
rsync -avz --delete /path/locale/ user@hostname:/path/remoto/

# Dry run (simula senza eseguire)
rsync -avzn /path/locale/ user@hostname:/path/remoto/

# Limitare la velocità di trasferimento
rsync --bwlimit=1000 -avz /path/locale/ user@hostname:/path/remoto/

# Escludere file/directory
rsync -avz --exclude='*.log' --exclude='node_modules/' \
  /path/locale/ user@hostname:/path/remoto/
```

***

## tcpdump

`tcpdump` cattura e analizza il traffico di rete in tempo reale. Fondamentale per il troubleshooting avanzato.

> ⚠️ Richiede privilegi di root o `sudo`.

```bash
# Catturare tutto il traffico sull'interfaccia eth0
tcpdump -i eth0

# Catturare traffico su una porta specifica
tcpdump -i eth0 port 80
tcpdump -i eth0 port 443

# Filtrare per host
tcpdump -i eth0 host 192.168.1.100

# Filtrare per protocollo
tcpdump -i eth0 tcp
tcpdump -i eth0 udp
tcpdump -i eth0 icmp

# Combinare filtri
tcpdump -i eth0 host 192.168.1.100 and port 80

# Mostrare output in formato leggibile (senza risoluzione nomi)
tcpdump -i eth0 -n -v

# Salvare la cattura su file (apribile con Wireshark)
tcpdump -i eth0 -w cattura.pcap

# Leggere un file .pcap
tcpdump -r cattura.pcap

# Limitare il numero di pacchetti catturati
tcpdump -i eth0 -c 100

# Catturare traffico HTTP (GET/POST)
tcpdump -i eth0 -A -s 0 'tcp port 80 and (((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)'
```

***

## host e whois

### host

```bash
# Risoluzione DNS semplice
host google.com

# Risoluzione inversa
host 8.8.8.8

# Record specifici
host -t MX gmail.com
host -t NS google.com
host -t TXT google.com
```

### whois

```bash
# Info su un dominio
whois google.com

# Info su un IP (organizzazione proprietaria)
whois 8.8.8.8

# Info su un ASN
whois AS15169
```

***

## Esercizi Pratici

### 🟢 Livello Base

**Esercizio 1 — Connettività di base**
1. Verifica che `google.com` sia raggiungibile con `ping` (invia esattamente 5 pacchetti)
2. Esegui un `traceroute` verso `8.8.8.8` senza risolvere i nomi DNS
3. Risolvi il nome `github.com` con `dig` e ottieni solo l'indirizzo IP (usa `+short`)

```bash
# Soluzioni attese:
ping -c 5 google.com
traceroute -n 8.8.8.8
dig +short github.com
```

**Esercizio 2 — curl base**
1. Fai una richiesta GET a `https://httpbin.org/get` e osserva la risposta
2. Fai una richiesta POST a `https://httpbin.org/post` con body JSON `{"nome": "Leonardo"}`
3. Verifica il codice HTTP di risposta di `https://google.com` (deve essere 301 o 200)

```bash
# Soluzioni attese:
curl https://httpbin.org/get
curl -X POST https://httpbin.org/post \
  -H "Content-Type: application/json" \
  -d '{"nome": "Leonardo"}'
curl -s -o /dev/null -w "%{http_code}" https://google.com
```

***

### 🟡 Livello Intermedio

**Esercizio 3 — Analisi porte**
1. Elenca tutte le porte TCP in ascolto sul tuo sistema con il processo associato
2. Verifica se la porta 22 (SSH) è in ascolto
3. Controlla quante connessioni TCP sono in stato `ESTABLISHED`

```bash
# Soluzioni attese:
ss -tlnp
ss -tlnp | grep :22
ss -tn state established | wc -l
```

**Esercizio 4 — DNS avanzato**
1. Trova i nameserver autoritativi di `amazon.com`
2. Scopri i record MX di `gmail.com` (server di posta)
3. Traccia la catena DNS completa di `stackoverflow.com` con `dig +trace`
4. Fai una query DNS usando il resolver di Cloudflare (`1.1.1.1`)

```bash
# Soluzioni attese:
dig +short NS amazon.com
dig +short MX gmail.com
dig +trace stackoverflow.com
dig @1.1.1.1 stackoverflow.com
```

**Esercizio 5 — curl avanzato**
1. Scarica il file `https://httpbin.org/image/png` salvandolo come `test.png`
2. Mostra solo gli header di risposta di `https://httpbin.org/headers`
3. Simula un browser Chrome con il corretto `User-Agent` facendo una richiesta a `https://httpbin.org/user-agent`
4. Fai una richiesta con autenticazione Basic (user: `user`, pass: `passwd`) a `https://httpbin.org/basic-auth/user/passwd`

```bash
# Soluzioni attese:
curl -o test.png https://httpbin.org/image/png
curl -I https://httpbin.org/headers
curl -A "Mozilla/5.0 Chrome/120.0" https://httpbin.org/user-agent
curl -u user:passwd https://httpbin.org/basic-auth/user/passwd
```

***

### 🔴 Livello Avanzato

**Esercizio 6 — Networking in Kubernetes**

> Prerequisito: accesso a un cluster Kubernetes o Minikube.

1. Fai un `port-forward` di un pod con `kubectl` e poi usa `curl` per testarlo
2. Dall'interno di un pod, usa `curl` per chiamare un altro servizio via DNS interno (`service.namespace.svc.cluster.local`)
3. Verifica la risoluzione DNS di un servizio Kubernetes con `dig` o `nslookup` dall'interno di un pod

```bash
# Esempio soluzioni:
kubectl port-forward pod/mio-pod 8080:8080 &
curl http://localhost:8080/health

# Dall'interno di un pod:
curl http://altro-servizio.default.svc.cluster.local:8080/api

# DNS lookup interno:
nslookup kubernetes.default.svc.cluster.local
```

**Esercizio 7 — Troubleshooting scenari reali**

Scenario: un collega ti dice che "il servizio non risponde". Segui questi step sistematici:

```bash
# Step 1: Il servizio è raggiungibile via rete?
ping -c 3 <HOST>

# Step 2: La porta è aperta?
nc -zv <HOST> <PORT>
# oppure
nmap -p <PORT> <HOST>

# Step 3: Il servizio risponde HTTP?
curl -v http://<HOST>:<PORT>/health

# Step 4: Dove si rompe il percorso?
traceroute -n <HOST>

# Step 5: Il DNS risolve correttamente?
dig +short <HOSTNAME>

# Step 6: Ci sono connessioni attive al servizio?
ss -tn dst <HOST>
```

**Esercizio 8 — Script di monitoring**

Scrivi uno script bash che:
1. Accetti un hostname come argomento
2. Verifichi se è raggiungibile via ping
3. Verifichi se le porte 80 e 443 sono aperte
4. Mostri il codice HTTP di risposta
5. Stampi un report finale

```bash
#!/bin/bash
HOST=${1:-"google.com"}
echo "=== Network Report per $HOST ==="

# Ping check
if ping -c 2 -q "$HOST" &>/dev/null; then
  echo "✅ Ping: RAGGIUNGIBILE"
else
  echo "❌ Ping: NON RAGGIUNGIBILE"
fi

# Port check
for PORT in 80 443; do
  if nc -zw2 "$HOST" $PORT 2>/dev/null; then
    echo "✅ Porta $PORT: APERTA"
  else
    echo "❌ Porta $PORT: CHIUSA"
  fi
done

# HTTP check
HTTP_CODE=$(curl -sk -o /dev/null -w "%{http_code}" --max-time 5 "https://$HOST")
echo "📡 HTTP Status Code: $HTTP_CODE"

# DNS
IP=$(dig +short "$HOST" | head -1)
echo "🔍 IP risolto: $IP"

echo "=== Fine Report ==="
```

***

## Cheat Sheet Rapido

```
CONNETTIVITÀ        ping, traceroute, mtr
DNS                 dig, nslookup, host
HTTP/API            curl, wget
PORT SCANNING       nmap, nc, telnet
PORTE LOCALI        ss, netstat
INTERFACCE          ip, ifconfig
FIREWALL            iptables, nftables
REMOTE ACCESS       ssh, scp, rsync
PACKET CAPTURE      tcpdump, wireshark
WHOIS/INFO          whois, host
```