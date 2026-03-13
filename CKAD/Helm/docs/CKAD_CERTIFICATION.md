# Guida Completa alla Certificazione CKAD

> 🌐 Sito ufficiale: [training.linuxfoundation.org/certification/ckad](https://training.linuxfoundation.org/certification/ckad/)  
> 📋 Curriculum ufficiale CNCF: [cncf.io/training/certification/ckad](https://www.cncf.io/training/certification/ckad/)  
> 📖 Documentazione Kubernetes: [kubernetes.io/docs](https://kubernetes.io/docs/home/)

---

## Cos'è la CKAD?

La **Certified Kubernetes Application Developer (CKAD)** è una certificazione
rilasciata dalla **Linux Foundation** in collaborazione con la **CNCF**
(Cloud Native Computing Foundation).

Certifica che il candidato è in grado di:
- Progettare, costruire e deployare applicazioni cloud-native su Kubernetes
- Configurare, esporre e monitorare workload Kubernetes
- Gestire sicurezza, risorse e configurazioni delle applicazioni

Non è un esame a risposta multipla: è **100% pratico**, tutto da terminale.

---


## Domini e Pesi

| Dominio                                          | Peso | Topic principali                                                                                      |
|--------------------------------------------------|------|-------------------------------------------------------------------------------------------------------|
| **Application Environment, Config & Security**   | 25%  | ConfigMap, Secret, ServiceAccount, SecurityContext, ResourceQuota, RBAC, CRD, Operators               |
| **Application Design and Build**                 | 20%  | Container images, Deployment, DaemonSet, CronJob, Job, multi-container Pod (sidecar, init), Volumi    |
| **Application Deployment**                       | 20%  | Rolling update, Blue/Green, Canary, Helm, Kustomize                                                   |
| **Services and Networking**                      | 20%  | Service (ClusterIP, NodePort, LB), Ingress, NetworkPolicy                                             |
| **Application Observability and Maintenance**    | 15%  | Probes, Logs, kubectl debug, API deprecations, Metrics                                                |

> 💡 Il dominio **Environment, Config & Security** vale da solo il 25%:
> ConfigMap, Secret, SecurityContext e RBAC sono quasi certamente presenti in esame.

---

## Argomenti per Dominio (dettaglio)

### 1. Application Design and Build (20%)
- Costruire e modificare immagini container (`docker build`, `FROM`, `COPY`, `CMD`)
- Scegliere il workload giusto: `Deployment`, `DaemonSet`, `StatefulSet`, `Job`, `CronJob`
- Pattern multi-container: **sidecar**, **init container**, **ambassador**, **adapter**
- Volumi ephemeral (`emptyDir`) e persistenti (`PVC`, `PV`, `StorageClass`)

### 2. Application Deployment (20%)
- Rolling update: `maxSurge`, `maxUnavailable`, `kubectl rollout`
- Strategie: Blue/Green (due Deployment + switch Service), Canary (peso repliche)
- Helm: `install`, `upgrade`, `rollback`, `values.yaml`
- Kustomize: `kustomization.yaml`, `bases`, `overlays`, `patches`

### 3. Application Observability and Maintenance (15%)
- `livenessProbe`, `readinessProbe`, `startupProbe`
- `kubectl logs`, `kubectl exec`, `kubectl top`
- `kubectl debug` (ephemeral containers)
- Deprecazioni API: `kubectl convert`, `kubectl api-versions`

### 4. Application Environment, Configuration and Security (25%)
- `ConfigMap`: creazione, mount come env o volume
- `Secret`: creazione, mount, tipi (`Opaque`, `kubernetes.io/dockerconfigjson`)
- `ResourceQuota`, `LimitRange`
- `ServiceAccount`: creazione, binding, mount automatico
- `SecurityContext`: `runAsUser`, `runAsNonRoot`, `readOnlyRootFilesystem`, `capabilities`
- RBAC: `Role`, `ClusterRole`, `RoleBinding`, `ClusterRoleBinding`
- CRD e Operators: riconoscerli e usarli (non crearli da zero)

### 5. Services and Networking (20%)
- `Service` tipi: `ClusterIP`, `NodePort`, `LoadBalancer`, `ExternalName`
- `Ingress`: regole host/path, TLS, ingress controller
- `NetworkPolicy`: `podSelector`, `namespaceSelector`, `ingress/egress` rules

---

## Ambiente d'Esame

L'esame si svolge in un **browser remoto** con accesso a un cluster Kubernetes reale.

Cosa è **permesso**:
- Una sola tab del browser su `kubernetes.io/docs`, `helm.sh/docs`, `github.com/kubernetes`
- Terminale bash con `kubectl`, `helm`, `vim`, `nano`, `curl`, `grep`

Cosa **NON è permesso**:
- Più tab browser
- Accesso a risorse esterne, GitHub personale, appunti online
- Copia-incolla da fonti esterne ai siti consentiti

> ⚠️ L'ambiente usa **Vim** come editor principale. Impara i comandi base:
> `i` (insert), `Esc`, `:wq` (salva+esci), `:q!` (esci senza salvare), `dd` (cancella riga),
> `yy` (copia riga), `p` (incolla), `u` (undo).

---

## Alias e Setup Consigliati (da fare subito all'inizio dell'esame)

```bash
# Alias kubectl → k (risparmia tempo su ogni comando)
alias k=kubectl

# Autocompletamento per k
source <(kubectl completion bash)
complete -F __start_kubectl k

# Export per dry-run rapido
export do="--dry-run=client -o yaml"
export now="--force --grace-period 0"

# Esempio uso:
k run nginx --image=nginx $do > pod.yaml   # Genera YAML senza creare il pod
k delete pod nginx $now                    # Cancella immediatamente
```