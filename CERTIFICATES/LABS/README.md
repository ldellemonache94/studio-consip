# Labs - Certificati

Percorso pratico progressivo.

## Regole
- Esegui ogni lab in ordine
- Leggi il README del lab prima di iniziare
- Non guardare la solution finché non hai provato
- Esegui sempre `verify.sh` per controllare il risultato

## Percorso

| Lab | Titolo | Prerequisito |
|-----|--------|--------------|
| lab01 | Root CA | nessuno |
| lab02 | Server cert | lab01 |
| lab03 | Chain of trust | lab02 |
| lab04 | Intermediate CA | lab03 |
| lab05 | mTLS | lab04 |
| lab06 | keytool / keystore | lab02 |
| lab07 | Kubernetes TLS Secret | lab02 + cluster K8s |
| lab08 | Kubernetes CSR API | lab07 |
| lab09 | cert-manager | lab08 |
| lab10 | Debugging | tutti i precedenti |

## Prerequisiti tecnici
- `openssl` installato
- `keytool` (JDK)
- `kubectl` + cluster Kubernetes (Kind o minikube vanno bene)
- `cert-manager` installato nel cluster per lab09
