# 08 - Kubernetes PKI

## Overview

Kubernetes ha una PKI interna che protegge tutte le comunicazioni tra i componenti del control plane.
Ogni componente si autentica con certificati X.509 tramite **mTLS**.

---

## Dove vivono i certificati

Default path: `/etc/kubernetes/pki/`

```
/etc/kubernetes/pki/
├── ca.crt / ca.key                    # Cluster CA
├── apiserver.crt / apiserver.key      # kube-apiserver server cert
├── apiserver-kubelet-client.crt/key   # apiserver → kubelet (client)
├── apiserver-etcd-client.crt/key      # apiserver → etcd (client)
├── front-proxy-ca.crt/key             # front-proxy CA
├── front-proxy-client.crt/key         # front-proxy client
├── sa.pub / sa.key                    # Service Account key pair
└── etcd/
    ├── ca.crt / ca.key                # etcd CA (separata)
    ├── server.crt / server.key
    ├── peer.crt / peer.key
    └── healthcheck-client.crt/key
```

---

## CA separate

Kubernetes usa CA **separate** per isolare i domini di trust:

| CA | Protegge |
|----|----------|
| `ca` | cluster generale (apiserver, kubelet, controller-manager, scheduler) |
| `etcd/ca` | comunicazioni interne etcd |
| `front-proxy-ca` | aggregation layer (extension API servers) |

> Separare le CA limita il blast radius: compromettere una CA non compromette automaticamente tutto il cluster.

---

## Componenti e certificati

| Componente | Ruolo cert | SAN obbligatori |
|------------|------------|-----------------|
| kube-apiserver | server | `kubernetes`, `kubernetes.default`, `kubernetes.default.svc`, IP del master |
| kubelet | client verso apiserver | CN=`system:node:<nodename>`, O=`system:nodes` |
| controller-manager | client | CN=`system:kube-controller-manager` |
| scheduler | client | CN=`system:kube-scheduler` |
| etcd | server + peer + client | IP di tutti i nodi etcd |

---

## Scadenza certificati

```bash
# Controlla scadenza di tutti i certificati del control plane
kubeadm certs check-expiration

# Rinnova tutti i certificati
kubeadm certs renew all

# Rinnova solo apiserver
kubeadm certs renew apiserver
```

> ⚠️ I certificati kubeadm hanno scadenza di **1 anno**. Pianifica il rinnovo.

---

## Verifiche manuali

```bash
# Dettagli cert apiserver
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout

# Verifica chain
openssl verify -CAfile /etc/kubernetes/pki/ca.crt /etc/kubernetes/pki/apiserver.crt

# Scadenza rapida
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -dates -noout
```

---

## kubeconfig e certificati

I file kubeconfig embeddano i certificati in base64:
```yaml
users:
- name: admin
  user:
    client-certificate-data: <base64(client.crt)>
    client-key-data: <base64(client.key)>
```

Decodifica rapida:
```bash
kubectl config view --raw | grep client-certificate-data | awk '{print $2}' | base64 -d | openssl x509 -text -noout
```

---

## Flash quiz

1. Quante CA separate ha Kubernetes di default?
2. Quale CA protegge etcd?
3. Qual è il CN del certificato kubelet?
4. Come verifichi la scadenza di tutti i cert con kubeadm?
5. Dove si trovano i certificati del control plane?
