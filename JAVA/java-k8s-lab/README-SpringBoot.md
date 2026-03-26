# ☕ Spring Boot su Kubernetes – JVM, memoria e comportamento reale

Questo documento estende il lab base usando una **vera applicazione Spring Boot**, senza introdurre strumenti di monitoring avanzati.

Obiettivo: capire come cambia il comportamento rispetto a una semplice app Java.

---

# 🚀 Setup

## 1. Genera app Spring Boot

Puoi usare Spring Initializr o creare un progetto con:

* Spring Web
* Spring Boot 3.x

## 2. Esempio Controller

```java
@RestController
public class MemoryController {

    private List<byte[]> memory = new ArrayList<>();

    @GetMapping("/eat")
    public String eat() {
        memory.add(new byte[5 * 1024 * 1024]); // 5MB
        return "Allocated: " + memory.size() * 5 + " MB";
    }
}
```

---

# 🐳 Dockerfile

```dockerfile
FROM eclipse-temurin:17-jdk

WORKDIR /app
COPY target/app.jar app.jar

ENTRYPOINT ["java", "-jar", "app.jar"]
```

---

# ☸️ Deployment base

```yaml
resources:
  limits:
    memory: "1Gi"
    cpu: "1"
  requests:
    memory: "512Mi"
    cpu: "0.5"
```

---

# 🧪 Esercizi

---

## 🟢 ESERCIZIO 1 – Carico controllato

Chiama endpoint:

```bash
curl http://<service>/eat
```

👉 Osserva:

* crescita heap graduale
* comportamento stabile

---

## 🟡 ESERCIZIO 2 – Senza Xmx

👉 Risultato:

* Spring Boot usa più memoria del previsto
* rischio OOMKilled

💡 Motivo:

* auto-configurazioni
* cache interne
* librerie

---

## 🔵 ESERCIZIO 3 – Con Xmx

```bash
-Xmx512m
```

👉 Risultato:

* comportamento prevedibile
* errori Java invece di kill container

---

## 🔴 ESERCIZIO 4 – Thread e CPU

Spring usa:

* thread pool Tomcat
* async tasks

👉 Limita CPU:

```yaml
cpu: "0.5"
```

Osserva:

* aumento latenza
* richieste più lente

---

## 🟣 ESERCIZIO 5 – GC reale

Avvia con:

```bash
-Xlog:gc*
```

👉 Vedrai:

* allocazioni rapide (HTTP requests)
* GC frequenti ma brevi

---

# 🧠 Differenze rispetto a MemoryEater

| Aspetto     | MemoryEater | Spring Boot   |
| ----------- | ----------- | ------------- |
| Allocazione | artificiale | realistica    |
| Thread      | pochi       | molti         |
| Memoria     | prevedibile | variabile     |
| GC          | semplice    | più stressato |

---

# ⚠️ Problemi tipici reali

### 🧨 OOMKilled

* heap troppo grande
* metaspace + overhead ignorato

### 💥 Memory leak

* cache non limitate
* bean singleton con stato

### 🐢 Performance

* CPU throttling
* thread pool mal dimensionati

---

# 🎯 Best practice

* heap ≈ 50–70% container
* sempre impostare `-Xmx`
* osservare GC logs
* evitare cache senza limite

---

# 🧠 Takeaway

> Spring Boot amplifica i problemi della JVM.
> Se capisci MemoryEater, qui capisci la produzione.

---

Fine 💥
