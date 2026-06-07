# 10 - cert-manager

## Cos'è

cert-manager è un controller Kubernetes che automatizza emissione e rinnovo di certificati TLS.
Aggiunge risorse custom (CRD) al cluster e gestisce il ciclo di vita dei certificati.

---

## Modello mentale

```
Issuer / ClusterIssuer
      ↓
  Certificate
      ↓
   Secret TLS
      ↓
    Pod / Ingress
```

---

## Risorse principali

### Issuer
CA namespaced. Emette certificati solo nel suo namespace.

```yaml
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: ca-issuer
  namespace: default
spec:
  ca:
    secretName: ca-key-pair
```

### ClusterIssuer
Come `Issuer`, ma cluster-wide. Può emettere in qualsiasi namespace.

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}
```

### Certificate
Richiede un certificato a un Issuer e lo salva in un Secret.

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: myapp-cert
  namespace: default
spec:
  secretName: myapp-tls
  issuerRef:
    name: ca-issuer
    kind: Issuer
  commonName: myapp.example.com
  dnsNames:
    - myapp.example.com
    - myapp.default.svc.cluster.local
  duration: 2160h
  renewBefore: 360h
```

---

## Tipi di Issuer

| Tipo | Quando usarlo |
|------|---------------|
| `selfSigned` | bootstrap iniziale, CA interna |
| `ca` | CA interna con chiave in Secret |
| `acme` | Let's Encrypt o altro ACME |
| `vault` | HashiCorp Vault |
| `venafi` | Venafi Trust Protection Platform |

---

## Rinnovo automatico

cert-manager monitora continuamente i `Certificate`.
Quando `notAfter - renewBefore` è nel passato, crea una nuova `CertificateRequest` e aggiorna il Secret.

Il pod che monta il Secret **non si riavvia automaticamente**: usa
[Reloader](https://github.com/stakater/Reloader) o un volume proiettato per forzare il reload.

---

## Verifica

```bash
kubectl get certificate -A
kubectl describe certificate myapp-cert
kubectl get secret myapp-tls -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout
cmctl renew myapp-cert
```

---

## Bootstrap CA interna (pattern comune)

```yaml
# 1. ClusterIssuer self-signed per creare la CA
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-bootstrap
spec:
  selfSigned: {}
---
# 2. Certificate per la CA (isCA: true)
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: internal-ca
  namespace: cert-manager
spec:
  isCA: true
  secretName: internal-ca-key-pair
  commonName: internal-ca
  issuerRef:
    name: selfsigned-bootstrap
    kind: ClusterIssuer
---
# 3. ClusterIssuer che usa la CA
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: internal-ca-issuer
spec:
  ca:
    secretName: internal-ca-key-pair
```

---

## Flash quiz

1. Differenza tra `Issuer` e `ClusterIssuer`?
2. In quale risorsa specifichi `dnsNames`?
3. Dove viene salvato il certificato emesso?
4. Come forzi il rinnovo manuale di un certificato?
5. Perché usare `isCA: true` in un `Certificate`?
