# Esercizio CKAD 8 – RBAC: Role, ClusterRole, RoleBinding

## Obiettivo
Configurare RBAC per un ServiceAccount applicativo con permessi minimi
(principio del least privilege): accesso in lettura ai pod, accesso
in scrittura ai configmap, nessun accesso ai secret.

**Difficoltà:** ⭐⭐⭐⭐ (intermedio-avanzato)  
**Dominio CKAD:** Application Environment, Config & Security (25%)  
**Tempo stimato:** 25 min

---

## Scenario
Un'applicazione (`app-reader`) gira in namespace `ckad-rbac` e ha bisogno di:
- **Leggere** pod (`get`, `list`, `watch`) nel proprio namespace
- **Leggere e scrivere** configmap (`get`, `list`, `create`, `update`, `delete`)
- **Nessun accesso** ai secret
- Un pod di test verifica i permessi con `kubectl auth can-i`

---

## Step 1 – Crea namespace e risorse base
```bash
k apply -f manifest/
k get sa,role,rolebinding -n ckad-rbac
```

---

## Step 2 – Verifica permessi con auth can-i
```bash
# Simula cosa può fare il ServiceAccount app-reader
k auth can-i get pods \
  --namespace=ckad-rbac \
  --as=system:serviceaccount:ckad-rbac:app-reader
# yes ✅

k auth can-i get secrets \
  --namespace=ckad-rbac \
  --as=system:serviceaccount:ckad-rbac:app-reader
# no ✅

k auth can-i create configmaps \
  --namespace=ckad-rbac \
  --as=system:serviceaccount:ckad-rbac:app-reader
# yes ✅

k auth can-i delete deployments \
  --namespace=ckad-rbac \
  --as=system:serviceaccount:ckad-rbac:app-reader
# no ✅
```

---

## Step 3 – Verifica dal pod (usa il SA montato automaticamente)
```bash
k exec -n ckad-rbac pod/app-reader-pod -- \
  kubectl get pods -n ckad-rbac
# Lista pod visibile ✅

k exec -n ckad-rbac pod/app-reader-pod -- \
  kubectl get secrets -n ckad-rbac
# Error from server (Forbidden) ✅
```

---

## Step 4 – Esercizio scritto
Aggiungi un secondo ServiceAccount `app-admin` che può fare tutto
(`verbs: ["*"]`) solo sui configmap. Crea il Role e RoleBinding
senza usare i file esistenti (scrivilo da zero con `--dry-run=client -o yaml`):
```bash
k create role configmap-admin \
  --verb="*" \
  --resource=configmaps \
  -n ckad-rbac \
  --dry-run=client -o yaml > manifest/role-admin.yaml

k create rolebinding configmap-admin-binding \
  --role=configmap-admin \
  --serviceaccount=ckad-rbac:app-admin \
  -n ckad-rbac \
  --dry-run=client -o yaml > manifest/rolebinding-admin.yaml
```

---

## Step 5 – Pulizia
```bash
k delete ns ckad-rbac
```

---

## Domande di verifica
1. Differenza tra `Role` e `ClusterRole`?
2. Differenza tra `RoleBinding` e `ClusterRoleBinding`?
3. Come verifichi i permessi di un ServiceAccount senza exec nel pod?
4. Cosa succede se associ un `ClusterRole` con un `RoleBinding`?
5. Perché è buona pratica evitare `verbs: ["*"]` in produzione?
```

***