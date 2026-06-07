# 09 - Kubernetes CSR API

## Concetto

La **Certificates API** (`certificates.k8s.io/v1`) permette di chiedere a Kubernetes di firmare una CSR PKCS#10, usando come CA quella del cluster.

È utile per emettere certificati per:
- workload che comunicano tra loro via mTLS
- utenti o service account custom
- componenti che devono autenticarsi verso kube-apiserver

---

## Oggetto CertificateSigningRequest

```yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: my-app-csr
spec:
  request: <base64 della CSR PEM>
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400
  usages:
    - client auth
```

### Signer built-in

| signerName | Cosa fa |
|------------|---------|
| `kubernetes.io/kube-apiserver-client` | client cert per autenticarsi verso apiserver |
| `kubernetes.io/kube-apiserver-client-kubelet` | client cert per kubelet |
| `kubernetes.io/kubelet-serving` | serving cert per kubelet |
| `kubernetes.io/legacy-unknown` | legacy, non garantisce firma automatica |

> `signerName` è **obbligatorio** in `certificates.k8s.io/v1`.

---

## Flusso completo

```bash
# 1. Genera chiave privata
openssl genrsa -out myapp.key 2048

# 2. Crea CSR
openssl req -new -key myapp.key \
  -subj "/CN=myapp/O=myteam" \
  -out myapp.csr

# 3. Codifica in base64
CSR_B64=$(cat myapp.csr | base64 | tr -d '\n')

# 4. Crea la risorsa CertificateSigningRequest
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: myapp-csr
spec:
  request: ${CSR_B64}
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400
  usages:
    - client auth
EOF

# 5. Approva la richiesta
kubectl certificate approve myapp-csr

# 6. Scarica il certificato firmato
kubectl get csr myapp-csr -o jsonpath='{.status.certificate}' | base64 -d > myapp.crt

# 7. Verifica
openssl x509 -in myapp.crt -text -noout
```

---

## Stato della CSR

```bash
kubectl get csr
# NAME        AGE   SIGNERNAME                            REQUESTOR   REQUESTEDDURATION   CONDITION
# myapp-csr   10s   kubernetes.io/kube-apiserver-client   admin       24h                 Pending

kubectl describe csr myapp-csr
```

| Condition | Significato |
|-----------|-------------|
| Pending | in attesa di approvazione |
| Approved | approvata, in attesa di firma |
| Denied | rifiutata |
| Failed | errore durante la firma |

---

## Note importanti

- La CSR **deve essere approvata** prima che il signer la firmi
- L'approvazione automatica dipende dal signer e dai permessi RBAC
- Il cert firmato va in `status.certificate` in base64
- Non tutti i signer garantiscono che il cert sia valido per la cluster CA pubblica

---

## Flash quiz

1. Cosa va in `spec.request`?
2. Qual è il `signerName` per autenticarsi verso kube-apiserver?
3. Come approvi una CSR con kubectl?
4. Dove si trova il certificato firmato dopo l'approvazione?
5. Cosa succede se usi `legacy-unknown` come signer?
