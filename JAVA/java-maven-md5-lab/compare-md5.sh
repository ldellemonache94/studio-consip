#!/usr/bin/env bash
# =============================================================
# COMPARE - Confronta gli MD5 delle due build
# Eseguire dopo step1 e step2
# =============================================================

echo "=============================================="
echo "  CONFRONTO HASH MD5 TRA LE DUE BUILD"
echo "=============================================="
echo ""

MD5_V1=$(cat build-v1.md5 2>/dev/null | tr -d '\n')
MD5_V2=$(cat build-v2.md5 2>/dev/null | tr -d '\n')

if [ -z "$MD5_V1" ] || [ -z "$MD5_V2" ]; then
    echo "ERRORE: uno o entrambi i file .md5 non esistono."
    echo "  Esegui prima step1-build.sh e poi step2-modify-and-build.sh"
    exit 1
fi

echo "  Build V1 (originale) : $MD5_V1"
echo "  Build V2 (modificata): $MD5_V2"
echo ""

if [ "$MD5_V1" = "$MD5_V2" ]; then
    echo "  [=] MD5 IDENTICI: il codice compilato non e' cambiato."
else
    echo "  [!] MD5 DIVERSI: la modifica al sorgente ha cambiato il JAR."
    echo "      Questo dimostra che anche piccole modifiche al codice"
    echo "      producono un hash completamente diverso (effetto valanga)."
fi

echo ""
echo "--- Verifica manuale ---"
echo "md5sum target/md5-demo-1.0-SNAPSHOT.jar"
md5sum target/md5-demo-1.0-SNAPSHOT.jar 2>/dev/null || echo "(esegui dopo mvn package)"
