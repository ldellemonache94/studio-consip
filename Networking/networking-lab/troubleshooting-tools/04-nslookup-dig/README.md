# 🔍 nslookup e dig — Diagnostica DNS

---

## Perché usare nslookup e dig?

Il **DNS è la fonte del 90% dei problemi di rete** che sembrano misteriosi.

Un servizio "che non funziona" spesso non è giù: semplicemente il suo nome
non si risolve, o si risolve nell'IP sbagliato, o la cache ha un valore vecchio.

`nslookup` e `dig` ti permettono di interrogare il DNS direttamente,
bypassando la cache del sistema operativo, scegliendo il resolver che vuoi,
e vedendo esattamente cosa risponde il DNS.

### La differenza tra i due

| Tool | Quando usarlo |
|---|---|
| `nslookup` | Verifiche rapide, più semplice da leggere, presente ovunque |
| `dig` | Troubleshooting serio, output dettagliato, scripting |

In ambienti professionali si usa quasi sempre `dig`.

---

## VPN: come cambia il DNS

Questo è **il caso più importante** per capire perché usare questi tool.

### Senza VPN

```bash
cat /etc/resolv.conf
# nameserver 192.168.1.1   ← DNS del tuo router di casa

dig google.com
# → risponde il DNS del router (o quello del tuo ISP)

dig server-interno.azienda.local
# → NXDOMAIN (non esiste! Il tuo DNS di casa non conosce i domini interni)
```
### Con VPN attiva
```bash
cat /etc/resolv.conf
# nameserver 10.0.0.1   ← DNS aziendale (cambiato dalla VPN!)

dig server-interno.azienda.local
# → risposta corretta! Il DNS aziendale conosce il dominio interno

dig google.com
# → funziona ancora (il DNS aziendale fa forward verso Internet)
```
### La domanda chiave sotto VPN
Quando connetti la VPN e qualcosa smette di funzionare, la prima domanda è:

```bash
# Il DNS è cambiato?
cat /etc/resolv.conf

# Il nome risolve con il resolver VPN?
dig @<DNS_VPN> nome-problematico.local

# Il nome risolve con il resolver pubblico?
dig @8.8.8.8 nome-problematico.local
```
### Split DNS (scenario comune in azienda)
Con split DNS:

I nomi *.azienda.local → risolti dal DNS aziendale (tramite VPN)

Tutti gli altri nomi → risolti dal DNS pubblico (diretto)

```bash
# Testa con i due resolver
dig @10.0.0.1 server-interno.azienda.local    # ← DNS aziendale: dovrebbe funzionare
dig @8.8.8.8  server-interno.azienda.local    # ← DNS Google: NXDOMAIN (normale!)
```

## DNS in Kubernetes: CoreDNS
In Kubernetes, il DNS è gestito da CoreDNS, un Pod nel namespace kube-system.
Ogni Pod del cluster usa CoreDNS come resolver (vedi /etc/resolv.conf del Pod).

```bash
# Da dentro un Pod
cat /etc/resolv.conf
# nameserver 10.96.0.10     ← IP di CoreDNS (kube-dns Service)
# search default.svc.cluster.local svc.cluster.local cluster.local

# Risolvi un Service interno
nslookup mio-service
# → risolve in ClusterIP del Service

# FQDN completo
nslookup mio-service.namespace.svc.cluster.local

# Verifica che CoreDNS risponda
nslookup kubernetes.default.svc.cluster.local
```

Esempi pratici con spiegazione
1. Risoluzione base
```bash
# nslookup
nslookup google.com

# dig - output completo
dig google.com

# dig - solo l'IP
dig +short google.com

# dig - solo la risposta (no metadata)
dig +noall +answer google.com
```

2. Record specifici
```bash
dig A google.com      # IPv4
dig AAAA google.com   # IPv6
dig MX gmail.com      # Mail server
dig NS google.com     # Nameserver autoritativi
dig TXT google.com    # Record TXT (SPF, verifica dominio, ecc.)
dig CNAME www.github.com  # Alias
```

3. Usa un resolver diverso
```bash
# Di default usa il resolver in /etc/resolv.conf
dig google.com

# Forza Cloudflare
dig @1.1.1.1 google.com

# Forza Google DNS
dig @8.8.8.8 google.com

# Forza il DNS aziendale (VPN)
dig @10.0.0.1 server-interno.azienda.local
```

Utile per isolare se il problema è il tuo resolver o il DNS stesso.

4. Traccia la catena DNS completa
```bash
dig +trace google.com
```
Mostra ogni step della risoluzione:

Root server (.)

TLD server (com.)

Nameserver autoritativo (google.com.)

Risposta finale

Utile per capire dove la catena si rompe in caso di problemi di propagazione DNS.

5. Risoluzione inversa (IP → nome)
```bash
dig -x 8.8.8.8
nslookup 8.8.8.8
```

Utile per identificare chi è il proprietario di un IP che vedi nei log.

6. Verifica propagazione DNS (dopo cambio record)
```bash
# Controlla se il record è propagato su più resolver
for DNS in 8.8.8.8 1.1.1.1 9.9.9.9 208.67.222.222; do
  echo -n "Resolver $DNS: "
  dig @$DNS +short A mio-dominio.com
done
```

7. Debug DNS in Kubernetes
```bash
# Controlla che CoreDNS risponda
kubectl exec -n default -it <any-pod> -- nslookup kubernetes.default

# Verifica la risoluzione di un Service
kubectl exec -n mio-namespace -it <pod> -- nslookup mio-service

# Se nslookup non c'è, usa wget
kubectl exec -n mio-namespace -it <pod> -- \
  wget -qO- http://mio-service/health

# Debug CoreDNS direttamente
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns
```


Esercizi
🟢 Esercizio 1 — Record base
```bash
# 1. Risolvi questi domini e conta gli IP
dig +short A google.com
dig +short A facebook.com
dig +short A cloudflare.com

# 2. Controlla gli IPv6
dig +short AAAA google.com

# 3. Trova i nameserver di questi domini
dig +short NS google.com
dig +short NS amazon.com
```

Domande:

Quanti IP ha google.com? Perché ne ha così tanti?

cloudflare.com ha record IPv6? Cosa significa avere IPv6?

🟢 Esercizio 2 — Confronta resolver diversi
```bash
for RESOLVER in 8.8.8.8 1.1.1.1 9.9.9.9; do
  echo -n "Resolver $RESOLVER → google.com: "
  dig @$RESOLVER +short google.com
done
```

Domande:

Ottieni gli stessi IP da tutti i resolver?

Prova con un dominio appena creato: tutti i resolver lo conoscono subito?

🟡 Esercizio 3 — Record MX e TXT
```bash
# MX di Gmail
dig +short MX gmail.com

# TXT di Google (contiene record SPF per anti-spam)
dig +short TXT google.com | grep spf

# TXT per verifica proprietà dominio (es. Google Search Console)
dig +short TXT google.com
```

Domande:

Quali mail server usa Gmail? Qual è la priorità più alta (numero più basso)?

Cosa dice il record SPF di Google? (hint: include:, ~all)

🟡 Esercizio 4 — Diagnosi problema DNS
Simula un problema DNS:
```bash
# Step 1: funziona con resolver pubblico?
dig @8.8.8.8 +short google.com

# Step 2: funziona con il resolver di sistema?
dig +short google.com

# Step 3: qual è il resolver di sistema?
cat /etc/resolv.conf

# Step 4: se non coincidono, qual è il problema?
```
Scenario da risolvere: un collega dice "non riesco ad accedere a github.com".
Esegui gli step sopra e descrivi come troveresti la causa.

🔴 Esercizio 5 — DNS checker script
Crea dns-check.sh:

```bash
cat > dns-check.sh << 'SCRIPT'
#!/usr/bin/env bash
# Verifica risoluzione DNS di una lista di domini su più resolver

DOMAINS=("google.com" "github.com" "stackoverflow.com")
RESOLVERS=("8.8.8.8" "1.1.1.1" "9.9.9.9")

echo "=== DNS Resolution Check ==="
echo ""
printf "%-25s" "DOMINIO"
for R in "${RESOLVERS[@]}"; do printf "%-20s" "$R"; done
echo ""
printf "%-25s" "-------"
for R in "${RESOLVERS[@]}"; do printf "%-20s" "-------------------"; done
echo ""

for DOMAIN in "${DOMAINS[@]}"; do
  printf "%-25s" "$DOMAIN"
  for RESOLVER in "${RESOLVERS[@]}"; do
    IP=$(dig @"$RESOLVER" +short +time=2 "$DOMAIN" 2>/dev/null | grep -E '^[0-9]+\.' | head -1)
    printf "%-20s" "${IP:-FALLITO}"
  done
  echo ""
done
SCRIPT
```
```bash
chmod +x dns-check.sh
./dns-check.sh
```