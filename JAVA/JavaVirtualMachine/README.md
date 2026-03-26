# JVM, memoria e CPU per microservizi Java in Kubernetes

Questo documento spiega in dettaglio cosa succede quando un microservizio Java parte dentro un pod Kubernetes:  
come viene avviata la JVM, come usa CPU e memoria del container, come funziona l’heap, la memoria nativa e il Garbage Collector (Shenandoah nel nostro caso).

Gli esempi sono basati su un caso reale del nostro cluster:

```yaml
apiVersion: v1
data:
  JAVA_SIZE_RAM_CONF: "-Xms2048m -Xmx3072m"
  JAVA_G1GC_CONF: "-XX:+UseShenandoahGC -XX:+UseContainerSupport -XX:MaxRAMPercentage=70.0 -XX:ShenandoahGCHeuristics=adaptive -XX:+UnlockExperimentalVMOptions -XX:ShenandoahUncommitDelay=1000 -XX:ShenandoahGuaranteedGCInterval=5000 -XX:+UseCompressedOops -XX:+UseCompressedClassPointers -XX:MaxDirectMemorySize=512m -XX:+UnlockDiagnosticVMOptions -XX:NativeMemoryTracking=summary"
  JAVA_OPT_CONF: "-Djava.security.egd=file:/dev/./urandom -Djava.awt.headless=true -Dweblogic.ssl.JSSEEnabled=true -Dweblogic.http.client.defaultReadTimeout=270000 -Dweblogic.http.client.defaultConnectTimeout=5000 -Dspring.profiles.active=prod -XX:+ClassUnloadingWithConcurrentMark"
kind: ConfigMap
metadata:
  name: bandoservice-java-properties-configmap
  namespace: impresacloud
```

E sulle risorse definite nel `values.yaml` del chart Helm:

```yaml
resources:
  limits:
    cpu: "4"
    memory: 6Gi
  requests:
    cpu: "2"
    memory: 2Gi
```

---

## 1. Dal pod Kubernetes al processo Java

### 1.1. Cosa succede quando il pod parte

1. Kubernetes crea il **pod** nel nodo.
2. Dentro il pod il runtime container (es. containerd) avvia un **container** con:
   - un **limite di CPU** (massimo 4 core, come da `limits.cpu`),
   - un **limite di memoria** (massimo 6Gi, come da `limits.memory`).
3. All’interno del container viene lanciato il processo `java` con i parametri presi dalla nostra ConfigMap.

Se immaginiamo il comando finale semplificato:

```bash
java \
  -Xms2048m -Xmx3072m \
  -XX:+UseShenandoahGC -XX:+UseContainerSupport -XX:MaxRAMPercentage=70.0 \
  -XX:ShenandoahGCHeuristics=adaptive \
  -XX:ShenandoahUncommitDelay=1000 \
  -XX:ShenandoahGuaranteedGCInterval=5000 \
  -XX:+UseCompressedOops -XX:+UseCompressedClassPointers \
  -XX:MaxDirectMemorySize=512m \
  -XX:+UnlockDiagnosticVMOptions -XX:NativeMemoryTracking=summary \
  -Djava.security.egd=file:/dev/./urandom \
  -Djava.awt.headless=true \
  -Dspring.profiles.active=prod \
  -jar app.jar
```

Il comportamento del microservizio, in termini di CPU e memoria, è il risultato combinato di:

- limiti e richieste di **Kubernetes**,
- configurazione interna della **JVM** (heap, GC, memoria nativa, thread, ecc.).

### 1.2. Requests e limits: cosa significano davvero

- `resources.requests.cpu: "2"`  
  Kubernetes pianifica il pod su un nodo assicurando che siano disponibili almeno **2 unità di CPU** (in pratica, 2 core logici equivalenti).

- `resources.limits.cpu: "4"`  
  Il container può consumare **al massimo 4 CPU**. Se il processo Java prova a usare più CPU, il cgroup lo “strozza” (throttling), quindi i thread girano più lentamente.

- `resources.requests.memory: 2Gi`  
  Kubernetes garantisce 2Gi di memoria per la pianificazione, ma **non limita** realmente l’uso a 2Gi.

- `resources.limits.memory: 6Gi`  
  È il tetto massimo di memoria per il container. Se il processo nel container supera questa soglia, il kernel invia OOM killer e il pod va in stato `OOMKilled`.

---

## 2. Come la JVM vede la memoria del container

### 2.1. Memoria totale vs memoria heap

Nel container abbiamo fino a **6Gi** di memoria.  
Questi 6Gi non sono tutti heap Java. Vengono usati per:

- Heap Java (dove vivono i nostri oggetti Java).
- Metaspace (classi, metadata).
- Stack dei thread.
- Buffer diretti (off-heap, es. `ByteBuffer.allocateDirect()`).
- Strutture della JVM, librerie native, JIT compiled code, ecc.
- Qualsiasi altro processo eventualmente nel container (in un microservizio tipico, solo il processo `java`).

Con:

```text
-Xms2048m -Xmx3072m
```

stiamo dicendo alla JVM:

- **Heap iniziale** (`-Xms`) = 2Gi.
- **Heap massimo** (`-Xmx`) = 3Gi.

Quindi:

- All’avvio, la JVM riserva già 2Gi di heap.
- Se servono più oggetti, l’heap può crescere **fino a 3Gi**.
- Oltre i 3Gi di heap, la JVM non allarga più l’heap e, se non riesce a liberare memoria col GC, genera un `java.lang.OutOfMemoryError: Java heap space`.

Se il processo, sommando:

- heap (max 3Gi),
- metaspace,
- stack dei thread,
- direct memory (massimo 512Mi, vedi sotto),
- altro overhead,

supera **6Gi**, non decide la JVM: decide il kernel che uccide il container (`OOMKilled`).

> Quindi abbiamo due tipi di OOM:  
> - **OOM Java**: `OutOfMemoryError` nei log dell’app (heap/metaspace/direct, ecc.).  
> - **OOM di sistema**: pod `OOMKilled` lato Kubernetes.

### 2.2. UseContainerSupport e MaxRAMPercentage

Nel nostro ConfigMap:

```text
-XX:+UseContainerSupport
-XX:MaxRAMPercentage=70.0
```

`UseContainerSupport` dice alla JVM: **“usa i limiti del container (cgroup) come memoria di riferimento”** invece della memoria fisica del nodo.

`MaxRAMPercentage=70.0` significa: “se non specifico direttamente `-Xmx`, calcola tu l’heap approssimativamente come il 70% della memoria disponibile”.

Nel nostro caso però abbiamo già impostato **esplicitamente**:

```text
-Xmx3072m
```

Quindi:

- la dimensione massima dell’heap è 3Gi, **non** viene ricalcolata da `MaxRAMPercentage`;
- `MaxRAMPercentage` rimane utile per altre aree (o è di fatto ridondante per l’heap).

---

## 3. Heap, generazioni e oggetti

### 3.1. Cos’è l’heap Java

L’heap è la regione di memoria dove vengono creati gli **oggetti** Java con `new`, dove vivono:

- i DTO delle API,
- gli oggetti di business,
- le collezioni (List, Map, Set),
- i buffer, stringhe, ecc.

Caratteristiche:

- È gestito interamente dalla **JVM** e dal **Garbage Collector**.
- Non devi liberare tu gli oggetti (come in C con `free`): quando non sono più raggiungibili, il GC li può eliminare.
- Se il codice alloca continuamente nuovi oggetti senza che vengano rilasciati (leak logici), l’heap cresce fino a `-Xmx` e poi arriva un `OutOfMemoryError`.

### 3.2. Heap e throughput

Nel nostro esempio:

- heap massimo = 3Gi,
- container massimo = 6Gi.

Possibili situazioni:

- Se l’heap sta sempre intorno a 1.5–2Gi, il GC lavora tranquillo e non avviciniamo i limiti.
- Se l’heap sta costantemente >2.8Gi, significa che:
  - generiamo molti oggetti che diventano garbage lentamente (es. grandi cache, tante collezioni lungoviventi),
  - oppure c’è un leak (qualcosa mantiene riferimenti e impedisce al GC di liberarli).

---

## 4. Memoria nativa, direct memory e metaspace

Oltre all’heap, la JVM usa altra memoria detta “nativa” o “off-heap”.

### 4.1. Metaspace

Il **Metaspace** contiene:

- le definizioni di classe,
- i metadata usati dalla JVM per gestire le classi.

In passato c’era la PermGen; ora c’è il Metaspace, che:

- non è limitato dall’heap,
- usa memoria nativa,
- può crescere fino al limite di memoria del processo (quindi del container).

Se abbiamo tantissime classi (molti jar, molte classi generate dinamicamente, code hot-swap, ecc.) il Metaspace può crescere molto.  
Un `OutOfMemoryError: Metaspace` significa che lo spazio per le classi è esaurito (o che non c’è più memoria nativa sufficiente).

### 4.2. Direct memory

Nel ConfigMap abbiamo:

```text
-XX:MaxDirectMemorySize=512m
```

La direct memory è usata da:

- `ByteBuffer.allocateDirect()`,
- alcuni driver (network, database, Netty, ecc.),
- meccanismi NIO.

Caratteristiche:

- è fuori dall’heap,
- viene comunque conteggiata nel limite dei 6Gi del container,
- è gestita da Java ma non rientra nel GC classico dell’heap (anche se è correlata).

`MaxDirectMemorySize=512m` mette un tetto di 512Mi alla memoria diretta; superata questa soglia, si possono avere errori tipo `OutOfMemoryError: Direct buffer memory`.

### 4.3. Stack dei thread e altre aree

Ogni thread Java ha uno **stack** (dimensione tipica 1–2Mi, ma configurabile).  
Se l’app crea moltissimi thread, la somma degli stack può occupare centinaia di MiB.

Altre aree:

- JIT code cache (codice nativo generato dal compilatore JIT),
- strutture interne della JVM,
- librerie native caricate (SSL, driver DB, ecc.).

Tutto questo concorre ai 6Gi totali del container.

---

## 5. CPU: come la JVM usa i core

### 5.1. Requests, limits e core “visti” dalla JVM

Con:

```yaml
requests:
  cpu: "2"
limits:
  cpu: "4"
```

- Kubernetes garantisce 2 core per la pianificazione, ma il container **può** usare fino a 4 core contemporaneamente se disponibili.
- La JVM, con `UseContainerSupport`, “vede” il numero di CPU del cgroup (in genere fino al limite).

Quindi:

- thread applicativi (es. thread pool Spring, thread Netty, ecc.) possono lavorare in parallelo su più core;
- il **Garbage Collector** (Shenandoah) usa thread dedicati in parallelo ai thread dell’app;
- se il carico è alto, la JVM sfrutta i 4 core, ma se tutti i pod del nodo usano il massimo, il kernel può fare scheduling più aggressivo e introdurre latenza.

### 5.2. Impatto sulla JVM

- Più core → GC più veloce (può parallelizzare le fasi di raccolta).
- Troppi core apparenti rispetto ai limiti effettivi → la JVM può creare troppi thread GC rispetto alla CPU realmente disponibile, causando inefficienza (più contesa).

---

## 6. Garbage Collector: Shenandoah in dettaglio

Nel nostro ConfigMap:

```text
-XX:+UseShenandoahGC
-XX:ShenandoahGCHeuristics=adaptive
-XX:ShenandoahUncommitDelay=1000
-XX:ShenandoahGuaranteedGCInterval=5000
```

### 6.1. Cos’è Shenandoah GC

Shenandoah è un GC **low-pause**, disegnato per ridurre al minimo i tempi in cui l’applicazione è completamente ferma.

A livello molto alto:

- La maggior parte del lavoro di spostamento/compattazione oggetti avviene **in parallelo** ai thread dell’applicazione.
- Le pause stop-the-world ci sono, ma sono molto brevi e mirate (per esempio per fasi di sincronizzazione).
- È pensato per servizi **latency-sensitive**, come i microservizi HTTP.

### 6.2. Heuristics: adaptive

`ShenandoahGCHeuristics=adaptive` significa che il GC:

- osserva il comportamento dell’heap (quanto cresce, quanta memoria viene recuperata),
- regola **quando** e **quanto aggressivamente** fare GC,
- tenta di bilanciare **throughput** (prestazioni) e **latenza** (pause brevi).

Altre heuristiche (che si potrebbero usare in altri contesti) sono `aggressive`, `compact`, ecc., ma qui usiamo `adaptive` come profilo generale.

### 6.3. Uncommit delay e guaranteed interval

- `ShenandoahUncommitDelay=1000` (millisecondi):  
  dopo un certo intervallo di inattività su una porzione di heap, Shenandoah può **rilasciare** memoria al sistema operativo.  
  Effetto:
  - riduce la memoria occupata quando il carico cala,
  - ma, se il carico cresce di nuovo, la JVM dovrà ri-ottenere memoria dal sistema, con un piccolo costo.

- `ShenandoahGuaranteedGCInterval=5000` (millisecondi):  
  assicura che almeno una GC avvenga ogni 5 secondi (se necessario).  
  Questo evita situazioni in cui, con poco carico, l’heap si riempie lentamente senza GC per lungo tempo, per poi avere una GC più pesante tutta insieme.

### 6.4. Cosa vedere nei log GC (idea base)

Un log GC tipico con Shenandoah mostra:

- uso di heap prima e dopo GC,
- durata delle varie fasi,
- se le GC sono frequenti e brevi (buono per la latenza),
- eventuali **Full GC** (campanello d’allarme, spesso indicano problemi di frammentazione o configurazione).

Nella documentazione avanzata si può aggiungere:

- come abilitare i log GC verbosi (`-Xlog:gc*,safepoint` su Java 11+),
- come leggere l’evoluzione dell’heap nel tempo.

---

## 7. Altri flag JVM importanti nel nostro caso

Dal nostro ConfigMap:

```text
-XX:+UseCompressedOops
-XX:+UseCompressedClassPointers
-XX:NativeMemoryTracking=summary
```

### 7.1. Compressed OOPs e class pointers

- `-XX:+UseCompressedOops`:
  - OOP = Ordinary Object Pointer.
  - Con la compressione, invece di usare un puntatore a 64 bit per ogni riferimento a oggetto, usa una rappresentazione compressa (tipicamente 32/35 bit).
  - Beneficio: **meno memoria** per i riferimenti, migliore utilizzo della cache CPU, potenziale miglioramento di performance.

- `-XX:+UseCompressedClassPointers`:
  - stessa idea, ma per i riferimenti alle classi e metadata.
  - riduce l’uso di memoria nella parte di Metaspace / classi.

Questi flag sono in genere consigliati finché la dimensione dell’heap non supera certe soglie (oltre le quali i benefici possono calare).

### 7.2. NativeMemoryTracking

- `-XX:NativeMemoryTracking=summary`:
  - abilita il tracciamento della memoria nativa.
  - con strumenti come `jcmd` è possibile vedere un riepilogo di dove sta andando la memoria (heap, metaspace, thread, code cache, ecc.).
  - utile in scenari di debug quando il pod viene ucciso per OOM ma l’heap non è a `-Xmx` (quindi il problema è altrove: direct memory, metaspace, ecc.).

---

## 8. Flag applicativi e comportamento runtime

Dal `JAVA_OPT_CONF`:

```text
-Djava.security.egd=file:/dev/./urandom
-Djava.awt.headless=true
-Dweblogic.ssl.JSSEEnabled=true
-Dweblogic.http.client.defaultReadTimeout=270000
-Dweblogic.http.client.defaultConnectTimeout=5000
-Dspring.profiles.active=prod
-XX:+ClassUnloadingWithConcurrentMark
```

Punti salienti:

- `-Dspring.profiles.active=prod`:
  - abilita il profilo `prod` in Spring Boot.
  - spesso in `prod` si usano impostazioni diverse di pool, cache, logging, ecc., che hanno impatto **reale** su memory footprint e CPU.

- `-Djava.security.egd=file:/dev/./urandom`:
  - evita blocchi sulla generazione di entropia (meno attese su `/dev/random`),
  - riduce spike di latenza all’avvio e durante l’uso di SSL/crypto.

- `-XX:+ClassUnloadingWithConcurrentMark`:
  - permette di scaricare classi non usate durante la concurrent mark (fase del GC),
  - riduce il rischio che il Metaspace cresca indefinitamente in applicazioni che caricano/rilasciano moduli dinamicamente.

---

## 9. Esempi pratici: scenari tipici

### 9.1. Scenario A: Heap sano, OOMKilled comunque

- Heap massimo (`-Xmx`): 3Gi.
- Nei log GC vediamo che l’heap oscilla tra 1.5Gi e 2Gi.
- Il pod viene comunque ucciso con `OOMKilled`.

Probabile causa:

- troppo **Metaspace**,
- troppa **direct memory** (vicina a 512Mi),
- oppure troppi thread (stack) o memoria nativa di librerie.

In questo caso:

- la JVM non ha un `OutOfMemoryError` (dal suo punto di vista va tutto bene),
- ma il processo supera comunque i 6Gi totali del container.

### 9.2. Scenario B: Heap al limite, OOM Java

- L’heap arriva spesso a 3Gi,
- molti `Full GC`,
- log con `java.lang.OutOfMemoryError: Java heap space`.

Allora:

- dobbiamo capire se:
  - aumentare `-Xmx` (avendo spazio nel container e nel nodo),
  - ridurre i dati in memoria (cache troppo grandi, collezioni mai liberate, leak),
  - cambiare strategie di caching/paginazione.

---

## 10. Come usare questo documento

Suggerimento per lo studio interno:

1. Leggere prima le sezioni 1–3 per capire il “giro” completo: pod → container → JVM → heap.
2. Passare alle sezioni 4–7 per entrare nel dettaglio di memoria nativa, direct memory, GC e flag.
3. Guardare nei nostri manifest Kubernetes reali:
   - ConfigMap con i flag JVM,
   - `values.yaml` con requests/limits.
4. Confrontare poi i comportamenti reali (uso memoria/CPU nei grafici del cluster, log GC, OOM) con i concetti spiegati qui.
