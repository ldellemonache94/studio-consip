# 🔧 Troubleshooting Tools — Guida al Networking Diagnostico

Questa sezione approfondisce i tool fondamentali che ogni DevOps/Developer usa
per diagnosticare problemi di rete.

Non si tratta solo di sapere la sintassi: si tratta di capire **perché** usi
quel tool, **cosa ti dice**, e **come cambia il comportamento** quando sei sotto VPN
o in ambienti di rete particolari come Kubernetes.

---

## Il problema che questi tool risolvono

Quando qualcosa "non funziona in rete", la domanda è: **dove si rompe la catena?**

La catena di una comunicazione di rete è questa:

[ Applicazione ]
↓
[ DNS: il nome si risolve? ]
↓
[ Rete IP: l'host è raggiungibile? ]
↓
[ TCP: la porta è aperta? ]
↓
[ Applicazione remota: risponde correttamente? ]


Ogni tool di questa sezione serve a testare **uno o più livelli** di questa catena.

---

## Mappa dei tool

| Tool | Livello testato | Domanda a cui risponde |
|------|----------------|----------------------|
| `ping` | IP / ICMP | "L'host è raggiungibile?" |
| `nslookup` / `dig` | DNS | "Il nome si risolve in un IP?" |
| `telnet` / `nc` | TCP (porta) | "La porta è aperta? Il servizio accetta connessioni?" |
| `curl` | HTTP/HTTPS (applicativo) | "L'API/servizio risponde correttamente?" |
| `wget` | HTTP/HTTPS (download) | "Riesco a scaricare questa risorsa?" |

---

## L'ordine corretto di troubleshooting

Quando un servizio non risponde, segui **sempre questo ordine**:

ping <host> → L'host è vivo?

nslookup <hostname> → Il DNS risolve?

nc -zv <host> <port> → La porta è aperta?

curl -v <url> → HTTP risponde?

text

Se un livello fallisce, **non andare avanti**: risolvi prima quello.

---

## VPN: come cambia tutto

Quando sei sotto VPN, la tua rete cambia radicalmente:

SENZA VPN:
[ La tua macchina ] → [ Router casa/ufficio ] → [ Internet ] → [ Server ]

CON VPN:
[ La tua macchina ] → [ VPN Tunnel ] → [ VPN Gateway aziendale ] → [ Rete interna ] → [ Server ]

text

Conseguenze pratiche:

- **DNS**: con VPN aziendale il resolver DNS cambia (usa quello interno)
- **IP sorgente**: i server ti vedono con l'IP del VPN Gateway, non il tuo
- **Routing**: alcune destinazioni passano per la VPN, altre no (split tunneling)
- **Firewall**: la VPN spesso blocca traffico ICMP (ping) verso host interni
- **Porte**: alcune porte potrebbero essere bloccate dal firewall aziendale anche in VPN

---

## Struttura esercizi

| Cartella | Tool | Livello |
|---|---|---|
| `01-curl/` | curl | 🟢→🔴 |
| `02-wget/` | wget | 🟢→🟡 |
| `03-ping/` | ping | 🟢→🟡 |
| `04-nslookup-dig/` | nslookup, dig | 🟢→🔴 |
| `05-telnet-nc/` | telnet, nc | 🟢→🔴 |