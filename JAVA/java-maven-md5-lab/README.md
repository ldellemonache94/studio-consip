# 🧪 Esercizio Maven – Generazione e Confronto Hash MD5

## Obiettivo

Dimostrare come una **build Maven** genera un hash MD5 diverso ogni volta che il codice sorgente viene modificato.  
L'esercizio si svolge su una **branch dedicata** (`feature/md5-demo`) staccata da `master`, eseguita su **WSL** (Windows Subsystem for Linux).

---

## 📋 Prerequisiti (WSL)

Verifica che tutto sia installato nel terminale WSL:

```bash
java -version    # Java 17+
mvn -version     # Maven 3.8+
git --version    # Git 2+
```

Se Maven non è installato:

```bash
sudo apt update && sudo apt install maven -y
```

---

## 📁 Struttura del Progetto

```
java-maven-md5-lab/
├── pom.xml                                    # Config Maven con checksum-plugin
├── README.md                                  # Questa guida
├── step1-build.sh                             # Script: prima build
├── step2-modify-and-build.sh                  # Script: build dopo modifica
├── compare-md5.sh                             # Script: confronto MD5
├── .gitignore
├── src/
│   ├── main/java/com/example/
│   │   ├── App.java                           # Sorgente v1 (originale)
│   │   └── App_v2.java                        # Sorgente v2 (modificato)
│   └── test/java/com/example/
│       └── AppTest.java                       # Test JUnit 5
├── build-v1.md5                               # (generato al STEP 1)
├── build-v2.md5                               # (generato al STEP 2)
└── last-build.md5                             # (ultima build prodotta)
```

---

## 🚀 Esecuzione Passo-Passo su WSL

### 0. Setup iniziale

```bash
# Clona il repository
git clone <URL_DEL_REPO>
cd java-maven-md5-lab

# Stacca un nuovo branch da master
git checkout master
git checkout -b feature/md5-demo

# Rendi eseguibili gli script
chmod +x step1-build.sh step2-modify-and-build.sh compare-md5.sh
```

---

### STEP 1 – Prima Build (codice originale)

```bash
./step1-build.sh
```

**Cosa succede:**
1. Maven compila `App.java` (versione 1 – solo metodo `greet`)
2. Il `checksum-maven-plugin` calcola l'MD5 del JAR prodotto
3. L'MD5 viene stampato a schermo e salvato in `build-v1.md5`

**Esempio output:**
```
>>> [STEP 1] Prima build Maven - branch feature/md5-demo

>>> JAR generato:
-rw-r--r-- 1 user user 4.2K Jan 01 12:00 target/md5-demo-1.0-SNAPSHOT.jar

>>> Hash MD5 del JAR (v1):
a3f8c2d1e5b7094f1c6a2e3b4d5f6789

>>> Salvato in build-v1.md5
```

**Commit intermedio:**
```bash
git add build-v1.md5 last-build.md5
git commit -m "feat(md5): prima build - hash MD5 v1 generato"
```

---

### STEP 2 – Modifica il Codice e Ri-builda

```bash
./step2-modify-and-build.sh
```

**Modifiche introdotte in `App_v2.java`:**
- Messaggio di `greet()` esteso: `"Hello, <name>! Welcome to the MD5 demo."`
- Aggiunto nuovo metodo `farewell(name)`

**Esempio output:**
```
>>> [STEP 2] Applicazione della modifica al sorgente
>>> App.java aggiornato con la versione 2

>>> JAR generato:
-rw-r--r-- 1 user user 4.5K Jan 01 12:05 target/md5-demo-1.0-SNAPSHOT.jar

>>> Hash MD5 del JAR (v2):
7e2b9c4f1d8a0356e2c7f1b3a4d5e890

>>> Salvato in build-v2.md5
```

> 📌 L'MD5 è **diverso** da quello del STEP 1!

**Commit intermedio:**
```bash
git add src/main/java/com/example/App.java build-v2.md5 last-build.md5
git commit -m "feat(md5): sorgente modificato - hash MD5 v2 diverso da v1"
```

---

### STEP 3 – Confronta gli MD5

```bash
./compare-md5.sh
```

**Output atteso:**
```
==============================================
  CONFRONTO HASH MD5 TRA LE DUE BUILD
==============================================

  Build V1 (originale) : a3f8c2d1e5b7094f1c6a2e3b4d5f6789
  Build V2 (modificata): 7e2b9c4f1d8a0356e2c7f1b3a4d5e890

  [!] MD5 DIVERSI: la modifica al sorgente ha cambiato il JAR.
      Questo dimostra che anche piccole modifiche al codice
      producono un hash completamente diverso (effetto valanga).
```

---

## 💡 Perché gli MD5 sono Diversi?

| Livello | Spiegazione |
|---|---|
| **Sorgente `.java`** | Il compilatore `javac` produce bytecode diverso se il sorgente cambia |
| **Bytecode `.class`** | Anche aggiungere un solo metodo cambia il file `.class` |
| **JAR finale** | Il JAR aggrega tutti i `.class`; se uno cambia, il JAR cambia |
| **Hash MD5** | Funzione deterministica: input diverso → output completamente diverso (effetto valanga) |
| **Uso pratico** | Maven Central, Nexus, Artifactory usano MD5/SHA per verificare l'integrità degli artefatti |

---

## 🌿 Workflow Git Completo

```bash
# --- Setup ---
git checkout master
git checkout -b feature/md5-demo

# --- STEP 1 ---
./step1-build.sh
git add build-v1.md5 last-build.md5
git commit -m "feat(md5): prima build - hash MD5 v1 generato"

# --- STEP 2 ---
./step2-modify-and-build.sh
git add src/main/java/com/example/App.java build-v2.md5 last-build.md5
git commit -m "feat(md5): sorgente modificato - hash MD5 v2 diverso da v1"

# --- Push branch ---
git push origin feature/md5-demo

# --- Pull Request verso master ---
# Apri la PR su GitHub dall'interfaccia web
```

---

## 🧹 Pulizia

```bash
mvn clean          # rimuove la cartella target/
```

---

## 📚 Riferimenti

- [checksum-maven-plugin](https://nicoulaj.github.io/checksum-maven-plugin/)
- [Maven Build Lifecycle](https://maven.apache.org/guides/introduction/introduction-to-the-lifecycle.html)
- [MD5 – Wikipedia](https://it.wikipedia.org/wiki/MD5)
- [Git Branching](https://git-scm.com/book/it/v2/Branching-in-Git)
