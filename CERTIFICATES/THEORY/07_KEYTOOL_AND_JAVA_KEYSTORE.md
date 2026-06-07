# 07 - keytool e Java Keystore

## Concetti fondamentali

### Keystore
Contiene la **chiave privata** e il **certificato pubblico** associato (e l'eventuale chain).
Usato lato applicazione per autenticarsi verso altri.

### Truststore
Contiene le **CA fidate** (certificati pubblici).
Usato per decidere di quali CA ci si fida quando si riceve un certificato.

> Regola: *chi sei* → keystore. *di chi ti fidi* → truststore.

### Formati
| Formato | Estensione | Note |
|---------|------------|------|
| JKS | `.jks` | Proprietario Java, deprecato |
| PKCS12 | `.p12` / `.pfx` | Standard, preferibile da Java 9+ |
| PEM | `.crt`, `.key` | Testo base64, usato da openssl |
| DER | `.der` | Binario, poco usato in Java |

---

## Flusso tipico

```
1. Genera keypair nel keystore
2. Crea CSR dal keystore
3. Firma la CSR con la CA
4. Importa la CA nel truststore
5. Importa il certificato firmato nel keystore
```

---

## Comandi keytool

### Generare un keypair
```bash
keytool -genkeypair \
  -alias myapp \
  -keyalg RSA \
  -keysize 2048 \
  -validity 365 \
  -dname "CN=myapp.example.com, O=MyOrg, C=IT" \
  -keystore myapp.p12 \
  -storetype PKCS12 \
  -storepass changeit
```

### Creare una CSR
```bash
keytool -certreq \
  -alias myapp \
  -file myapp.csr \
  -keystore myapp.p12 \
  -storetype PKCS12 \
  -storepass changeit
```

### Importare la CA nel truststore
```bash
keytool -importcert \
  -alias root-ca \
  -file ca.crt \
  -keystore truststore.p12 \
  -storetype PKCS12 \
  -storepass changeit \
  -noprompt
```

### Importare il certificato firmato nel keystore
```bash
keytool -importcert \
  -alias myapp \
  -file myapp-signed.crt \
  -keystore myapp.p12 \
  -storetype PKCS12 \
  -storepass changeit
```

### Listare i contenuti
```bash
keytool -list -v \
  -keystore myapp.p12 \
  -storetype PKCS12 \
  -storepass changeit
```

### Esportare un certificato
```bash
keytool -exportcert \
  -alias myapp \
  -file myapp-exported.crt \
  -keystore myapp.p12 \
  -storetype PKCS12 \
  -storepass changeit
```

### Convertire JKS → PKCS12
```bash
keytool -importkeystore \
  -srckeystore old.jks \
  -srcstoretype JKS \
  -destkeystore new.p12 \
  -deststoretype PKCS12
```

---

## Differenza con openssl

| Aspetto | keytool | openssl |
|---------|---------|--------|
| Gestione keystore | sì (JKS/PKCS12) | no (file separati) |
| Genera chiave privata | sì (dentro keystore) | sì (file .key) |
| Crea CSR | sì | sì |
| Firma certificati | no | sì (CA role) |
| Converte formati | limitato | molto flessibile |
| Ecosistema | Java/JVM | tutto |

---

## Note per Kubernetes

- I pod Java devono leggere CA e cert da `Secret` o `ConfigMap`
- Il secret TLS in K8s contiene `tls.crt` e `tls.key` in PEM
- Per Java devi importare `tls.crt` nel keystore e le CA nel truststore all'avvio
- Script di init container per costruire keystore al volo sono comuni in enterprise

---

## Flash quiz

1. Cosa metti nel keystore?
2. Cosa metti nel truststore?
3. Qual è il formato preferibile tra JKS e PKCS12?
4. Come esporti un certificato con keytool?
5. Perché non usi keytool per firmare certificati?
