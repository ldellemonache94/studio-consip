#!/bin/bash

echo "DEMO GitFlow: revert vs reset su branch RC"
echo "=========================================================="
echo ""

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}STATO INIZIALE (con feature-bug.txt presente)${NC}"
echo "Codice nel branch RC:"
cat app.txt feature-bug.txt 2>/dev/null
echo ""
echo "MD5 prima (pre-prod):"
md5sum app.txt feature-bug.txt 2>/dev/null || echo "md5sum app.txt feature-bug.txt"
echo -e "${GREEN} Pre-prod OK - MD5 calcolato${NC}\n"

read -p "Premi ENTER per simulare REVERT (sbagliato)..."

echo -e "${RED} SCENARIO 1: git revert HEAD${NC}"
echo "Crea commit 'Revert feature sbagliata' + spinge"
echo "Risultato:"
echo "  * Storia: feat + revert (2 commit inutili)"
echo "  * MD5 CAMBIA → Deploy PROD FALLISCE"
echo "  * Merge su master porta 'rumore'"
echo ""
git log --oneline -3 2>/dev/null | head -3 || echo "git log --oneline -3"
echo -e "${RED}PROBLEMA: Storia SPORCA + MD5 rotto${NC}\n"

read -p "Premi ENTER per simulare RESET (corretto)..."

echo -e "${GREEN} SCENARIO 2: git reset --hard HEAD~1${NC}"
echo "Rimuove commit dalla storia + force push"
echo "Risultato:"
echo "  * Storia: PULITA (solo commit buoni)"
echo "  * MD5 IDENTICO → Deploy PROD OK"
echo "  * Merge su master perfetto"
echo ""
echo "Dopo reset, feature-bug.txt:"
ls -la feature-bug.txt 2>/dev/null || echo "FILE ELIMINATO dalla storia!"
echo ""
git log --oneline -1 2>/dev/null || echo "git log --oneline -1"
echo -e "${GREEN}PERFETTO: Pronto per PROD e merge su master!${NC}\n"

echo "LA LEZIONE ha l'obiettivo di insegnare:"
echo "  Su RC: ${RED}NO revert${NC} → ${GREEN}SI reset${NC} (se branch non ancora finale)"
echo "=========================================================="