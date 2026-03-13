# ATTENZIONE AI COMANDI CHE LANCIATE NON MI PRENDO RESPONSABILITA' :)
***
```markdown
# Connettività verso Internet dal Pod

**Livello:** Avanzato  
**Strumenti:** `curl`, `dig`, `nslookup`, `wget`  
**Prerequisito:** Esercizi 01-03 completati

## Cosa imparerai

- Come un Pod esce su Internet (NAT)
- Quale IP pubblico vede il mondo quando un Pod chiama verso l'esterno
- Differenza tra risoluzione DNS interna ed esterna nel cluster
- Come diagnosticare problemi di connettività verso l'esterno

---

## Esercizio 1 — Il Pod riesce ad uscire su Internet?

Entra in `net-netshoot`:

```bash
kubectl exec -n lab-networking -it net-netshoot -- bash
```

Ecco il contenuto **formattato correttamente in Markdown**:

````markdown
Dentro il Pod:

```text
# Test HTTP verso Internet
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" https://google.com

# Scopri con quale IP pubblico esci
curl -s https://ifconfig.me && echo ""

# Alternativa
curl -s https://api.ipify.org && echo ""
````

### Domande

* Il Pod riesce ad uscire?
* Quale **IP pubblico** vedi? È lo stesso dell'IP del nodo?
* Cosa significherebbe se l'IP fosse diverso dall'IP del nodo?

---

# Esercizio 2 — DNS interno vs esterno

Dentro **net-netshoot**:

```text
# Risoluzione DNS interna (Service del cluster)
nslookup kubernetes.default.svc.cluster.local

# Risoluzione DNS esterna (Internet)
nslookup google.com
dig +short google.com
dig +short github.com
```

Poi guarda il **resolver configurato**:

```text
cat /etc/resolv.conf
```

### Domande

* Lo stesso server DNS (**CoreDNS**) serve sia i nomi **interni** che quelli **esterni**?
* Come fa CoreDNS a gestire entrambi?
* Cosa succede se **CoreDNS va giù**? Cosa smette di funzionare?

<details>
<summary>💡 Risposta</summary>

CoreDNS gestisce sia i **nomi interni** (tramite il plugin `kubernetes`) sia i **nomi esterni** (tramite il plugin `forward`, che di default punta al DNS del nodo host).

Se CoreDNS va giù:

* I nomi interni al cluster **non si risolvono più** → i Pod non trovano i Service
* Anche la **risoluzione esterna** smette di funzionare dal cluster

</details>

---

# Esercizio 3 — Troubleshooting guidato

Simula un problema modificando temporaneamente il **CoreDNS ConfigMap**:

```bash
# ATTENZIONE: modifica in un cluster di TEST
kubectl edit configmap coredns -n kube-system
```

Nella sezione `forward`, cambia `8.8.8.8` con un IP inesistente (es. `1.2.3.4`), salva ed aspetta qualche secondo.

Poi da dentro il Pod:

```text
dig +short google.com
curl --max-time 5 https://google.com
```

### Domande

* Cosa succede alla **risoluzione DNS esterna**?
* I **Service interni** funzionano ancora?

Ripristina la **configurazione originale** dopo il test.

---

# Esercizio 4 — Script di health check esterno

Dentro **net-netshoot**, scrivi ed esegui questo script:

```text
cat > /tmp/ext-check.sh << 'SCRIPT'
#!/bin/sh
echo "=== External Connectivity Check ==="

# DNS
IP=$(dig +short google.com | head -1)
if [ -n "$IP" ]; then
  echo "✅ DNS esterno: google.com risolto in $IP"
else
  echo "❌ DNS esterno: FALLITO"
fi

# HTTP
CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 https://google.com)
if [ "$CODE" -ge 200 ] && [ "$CODE" -lt 400 ]; then
  echo "✅ HTTP esterno: $CODE"
else
  echo "❌ HTTP esterno: $CODE"
fi

# IP pubblico
PUB_IP=$(curl -s --max-time 5 https://api.ipify.org)
echo "🌍 IP pubblico uscita: $PUB_IP"
SCRIPT

chmod +x /tmp/ext-check.sh
/tmp/ext-check.sh
```