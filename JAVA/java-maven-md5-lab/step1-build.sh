#!/usr/bin/env bash
# =============================================================
# STEP 1 - Prima build: genera il JAR e il suo hash MD5
# Eseguire dalla root del repository su WSL
# =============================================================
set -e

echo ">>> [STEP 1] Prima build Maven - branch feature/md5-demo"
echo ""

# Assicurarsi di essere sul branch corretto
git status 2>/dev/null | head -1 || true

# Build pulita
mvn clean package -q

echo ""
echo ">>> JAR generato:"
ls -lh target/*.jar

echo ""
echo ">>> Hash MD5 del JAR (v1):"
cat last-build.md5

echo ""
# Salva l'MD5 v1 per il confronto
cp last-build.md5 build-v1.md5
echo ">>> Salvato in build-v1.md5"
echo ""
echo "Ora modifica il sorgente ed esegui: ./step2-modify-and-build.sh"
