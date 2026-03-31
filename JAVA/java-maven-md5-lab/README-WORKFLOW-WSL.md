# 🚀 Workflow su WSL
## Setup iniziale
```bash
git clone <URL_REPO> && cd maven-md5-exercise
git checkout master
git checkout -b feature/md5-demo-nome        # branch staccato da master
chmod +x *.sh
```
### STEP 1 – Prima build
```bash
./step1-build.sh
# → compila App.java v1, genera JAR, calcola MD5 → build-v1.md5
git add build-v1.md5 && git commit -m "feat(md5): prima build - hash v1"
```
### STEP 2 – Modifica codice e rebuild
```bash
./step2-modify-and-build.sh
# → sovrascrive App.java con v2, rebuilda, genera nuovo MD5 → build-v2.md5
git add src/main/java/com/example/App.java build-v2.md5
git commit -m "feat(md5): codice modificato - hash v2 diverso"
```
STEP 3 – Confronto
```bash
./compare-md5.sh
# Output: "MD5 DIVERSI: la modifica al sorgente ha cambiato il JAR"
```

### Push e PR
```bash
git push origin feature/md5-demo-nome
# poi apri la Pull Request verso master su GitHub
```

# 💡 Concetto chiave dimostrato
Il checksum-maven-plugin genera l'MD5 del JAR durante la fase package del lifecycle Maven. Anche una sola riga di codice modificata cambia il bytecode .class, e quindi il JAR finale — per la proprietà dell'effetto valanga dell'MD5: input diverso → hash completamente diverso. Questo è esattamente il meccanismo che Maven Central usa per verificare l'integrità degli artefatti distribuiti.