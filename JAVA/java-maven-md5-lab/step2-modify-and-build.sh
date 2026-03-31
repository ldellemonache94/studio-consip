#!/usr/bin/env bash
# =============================================================
# STEP 2 - Sostituisce App.java con la versione modificata
#          e ri-esegue la build Maven
# Eseguire dalla root del repository su WSL
# =============================================================
set -e

echo ">>> [STEP 2] Applicazione della modifica al sorgente"
echo ""

# Sostituisce App.java con la versione modificata
cp src/main/java/com/example/App_v2.java src/main/java/com/example/App.java
echo ">>> App.java aggiornato con la versione 2 (metodo farewell aggiunto)"
echo ""

# Build pulita
mvn clean package -q

echo ""
echo ">>> JAR generato:"
ls -lh target/*.jar

echo ""
echo ">>> Hash MD5 del JAR (v2):"
cat last-build.md5

echo ""
# Salva l'MD5 v2 per il confronto
cp last-build.md5 build-v2.md5
echo ">>> Salvato in build-v2.md5"
echo ""
echo "Ora esegui: ./compare-md5.sh"
