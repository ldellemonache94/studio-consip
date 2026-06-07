# 📖 Risorse di Studio — Certificati TLS/SSL

## 🎯 Percorso consigliato

Seguire questo ordine per costruire la conoscenza in modo progressivo.

---

## Livello 1 — Fondamentali (inizia qui)

### Letture
- 📄 **Cloudflare Learning: What is TLS?**  
  https://www.cloudflare.com/learning/ssl/transport-layer-security-tls/

- 📄 **Mozilla Developer Network: TLS**  
  https://developer.mozilla.org/en-US/docs/Web/Security/Transport_Layer_Security

- 📄 **RFC 5280** — X.509 Certificate and CRL Profile (focus su Section 4)  
  https://www.rfc-editor.org/rfc/rfc5280

### Video
- 🎥 **TLS Handshake Explained** — Hussein Nasser (YouTube)  
  Cerca: `TLS Handshake Hussein Nasser`  
  *Ottimo per capire il flusso visivamente*

- 🎥 **Public Key Cryptography** — Computerphile  
  Cerca: `Public Key Cryptography Computerphile`

---

## Livello 2 — Pratica con OpenSSL

### Risorse
- 📄 **OpenSSL Cookbook** (Ivan Ristić) — gratuito online  
  https://www.feistyduck.com/library/openssl-cookbook/

- 📄 **OpenSSL man pages**
  ```bash
  man openssl-req
  man openssl-x509
  man openssl-verify
  man openssl-s_client
  ```

### Tool utili online
- 🔧 **SSL Labs Server Test** — analizza un server TLS reale  
  https://www.ssllabs.com/ssltest/

- 🔧 **CertLogik** — decodifica certificati online  
  https://certlogik.com/decoder/

- 🔧 **keystore-explorer** — GUI per gestire certificati JKS/PKCS12 (utile per WebLogic)  
  https://keystore-explorer.org/

---

## Livello 3 — Approfondimenti

### TLS 1.3
- 📄 **RFC 8446** — TLS 1.3 (spec ufficiale)  
  https://www.rfc-editor.org/rfc/rfc8446

- 📄 **Cloudflare Blog: TLS 1.3**  
  https://blog.cloudflare.com/rfc-8446-aka-tls-1-3/

### mTLS e Zero Trust
- 📄 **Cloudflare: What is mTLS?**  
  https://www.cloudflare.com/learning/access-management/what-is-mutual-tls/

- 📄 **SPIFFE/SPIRE** — standard per identità dei workload in ambienti cloud-native  
  https://spiffe.io/docs/latest/spiffe-about/overview/

### Kubernetes e Certificati
- 📄 **Kubernetes PKI Certificates and Requirements**  
  https://kubernetes.io/docs/setup/best-practices/certificates/

- 📄 **cert-manager** — gestione automatica certificati in K8s  
  https://cert-manager.io/docs/concepts/

- 📄 **Kubeadm: Manage certificates**  
  https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/

---

## 📝 Checklist di Autovalutazione

Dopo aver completato teoria ed esercizi, verifica di saper rispondere:

### Concetti base
- [ ] Cos'è un certificato X.509 e quali sono i suoi campi principali?
- [ ] Qual è la differenza tra Subject e Issuer?
- [ ] Cos'è una CSR e perché si usa?
- [ ] Cos'è la Chain of Trust e come viene verificata?
- [ ] Cosa sono i SAN e perché sono obbligatori nei browser moderni?

### TLS Handshake
- [ ] Sai descrivere i passi del TLS 1.2 Handshake?
- [ ] Come viene derivata la chiave di sessione?
- [ ] Cosa cambia nel TLS 1.3 rispetto al 1.2?
- [ ] Cos'è la Perfect Forward Secrecy (PFS)?

### Self-Signed e PKI
- [ ] Quando si usa un certificato self-signed?
- [ ] Qual è la differenza tra Root CA e Intermediate CA?
- [ ] Come si aggiunge una CA custom al trust store di Linux?
- [ ] Come si aggiunge una CA custom al trust store di Java/WebLogic?

### mTLS
- [ ] Qual è la differenza tra TLS e mTLS?
- [ ] In quale step dell'Handshake il server richiede il certificato client?
- [ ] Dove si usa mTLS in Kubernetes?
- [ ] Cosa fa un Service Mesh come Istio con mTLS?

### OpenSSL pratica
- [ ] Sai creare una Root CA da zero?
- [ ] Sai generare una CSR e firmarla con SAN?
- [ ] Sai ispezionare un certificato con `openssl x509 -text`?
- [ ] Sai verificare la chain di un certificato?
- [ ] Sai convertire tra formati PEM, DER e PKCS12?
- [ ] Sai verificare che chiave e certificato corrispondano?
