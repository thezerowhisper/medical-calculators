#!/bin/bash
# Run from inside ~/medical-calculators/
# Fixes remaining canonical .html issues, then commits everything

RED='\033[0;31m'; GRN='\033[0;32m'; YEL='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'
ok()  { echo -e "  ${GRN}✓${NC} $1"; }
fix() { echo -e "  ${YEL}~${NC} $1"; }
err() { echo -e "  ${RED}✗${NC} $1"; }

echo -e "\n${BOLD}[1] FINDING remaining canonical .html files${NC}"
grep -rl 'canonical.*\.html' . --include="*.html"

echo -e "\n${BOLD}[2] FIXING all canonical .html → clean URLs${NC}"
BASE="https://thezerowhisper.github.io/medical-calculators"

for f in *.html; do
  if grep -q 'rel="canonical".*\.html' "$f" 2>/dev/null; then
    # Extract slug from filename (strip .html)
    SLUG="${f%.html}"
    CLEAN_URL="$BASE/$SLUG"
    sed -i "s|<link rel=\"canonical\" href=\"[^\"]*\"|<link rel=\"canonical\" href=\"${CLEAN_URL}\"|g" "$f"
    ok "Fixed canonical in $f → $CLEAN_URL"
  fi
done

# Special case: index.html canonical should be the base URL
if grep -q 'rel="canonical"' index.html 2>/dev/null; then
  CURRENT=$(grep -oP '(?<=canonical" href=")[^"]+' index.html)
  if [[ "$CURRENT" == *"index"* ]] || [[ "$CURRENT" == *".html"* ]]; then
    sed -i 's|<link rel="canonical" href="[^"]*"|<link rel="canonical" href="https://thezerowhisper.github.io/medical-calculators/"|g' index.html
    ok "Fixed index.html canonical → $BASE/"
  fi
fi

echo -e "\n${BOLD}[3] VERIFICATION${NC}"
REMAINING=$(grep -rl 'canonical.*\.html' . --include="*.html" | wc -l)
[ "$REMAINING" -eq 0 ] && ok "All canonical tags clean — zero .html remaining" || err "$REMAINING still have .html in canonical:"
[ "$REMAINING" -gt 0 ] && grep -rl 'canonical.*\.html' . --include="*.html"

echo -e "\n${BOLD}[4] GIT COMMIT & PUSH${NC}"
git add -A
git status --short
echo -e "\n${YEL}Press Enter to commit and push, Ctrl+C to cancel.${NC}"
read -r
git commit -m "SEO fix: all canonical + og:url .html stripped, schema fixed, duplicate removed, H1 fixed"
git push
echo -e "\n${GRN}${BOLD}Done! Wait 2 min then re-run audit.sh${NC}\n"
