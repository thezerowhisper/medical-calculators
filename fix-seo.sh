#!/bin/bash

# Run from inside ~/medical-calculators/
# Usage: bash ~/fix-seo.sh

RED='\033[0;31m'; GRN='\033[0;32m'; YEL='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'
ok()  { echo -e "  ${GRN}✓${NC} $1"; }
fix() { echo -e "  ${YEL}~${NC} $1"; }
err() { echo -e "  ${RED}✗${NC} $1"; }

echo -e "\n${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  Medical Calculators — SEO Auto-Fix${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Verify we're in the right place
if [ ! -f "index.html" ] || [ ! -f "sitemap.xml" ]; then
  err "Run this from inside ~/medical-calculators/ directory"
  exit 1
fi

# ── 1. Delete duplicate file ──────────────────────────────────────────────────
echo -e "${BOLD}[1] DUPLICATE FILES${NC}"
if [ -f "curb65 (1).html" ]; then
  rm "curb65 (1).html"
  ok "Deleted 'curb65 (1).html'"
else
  ok "No duplicates found"
fi

# ── 2. Fix og:url .html → clean URL (all files) ──────────────────────────────
echo -e "\n${BOLD}[2] FIX og:url .html → clean URLs${NC}"
BEFORE=$(grep -rl 'og:url.*\.html' . --include="*.html" | wc -l)
fix "Found $BEFORE files with .html in og:url"

for f in *.html; do
  if grep -q 'og:url.*\.html' "$f"; then
    sed -i 's|<meta property="og:url" content="\(https://[^"]*\)\.html"|<meta property="og:url" content="\1"|g' "$f"
    ok "Fixed og:url in $f"
  fi
done

AFTER=$(grep -rl 'og:url.*\.html' . --include="*.html" | wc -l)
if [ "$AFTER" -eq 0 ]; then
  ok "All og:url .html issues resolved"
else
  err "$AFTER files still have .html in og:url — check manually"
fi

# ── 3. Fix canonical .html → clean URL (specific files) ──────────────────────
echo -e "\n${BOLD}[3] FIX canonical .html → clean URLs${NC}"

fix_canonical() {
  local file="$1"
  local clean_url="$2"
  if [ -f "$file" ]; then
    if grep -q 'canonical.*\.html' "$file"; then
      sed -i "s|<link rel=\"canonical\" href=\"[^\"]*\"|<link rel=\"canonical\" href=\"${clean_url}\"|g" "$file"
      ok "Fixed canonical in $file → $clean_url"
    else
      ok "$file canonical already clean"
    fi
  else
    err "$file not found"
  fi
}

BASE="https://thezerowhisper.github.io/medical-calculators"
fix_canonical "uip-vaccine.html"     "$BASE/uip-vaccine"
fix_canonical "due-date.html"        "$BASE/due-date"
fix_canonical "growth-chart.html"    "$BASE/growth-chart"

# Also fix schema JSON-LD .html URLs in these files
echo -e "\n${BOLD}[4] FIX schema JSON-LD .html URLs${NC}"
for f in *.html; do
  if grep -q '\.html"' "$f" && grep -q 'application/ld+json' "$f"; then
    # Fix .html inside JSON-LD blocks only (between ld+json script tags)
    python3 -c "
import re, sys
content = open('$f').read()
def fix_jsonld(m):
    return re.sub(r'(thezerowhisper\.github\.io/[^\"]*?)\.html', r'\1', m.group(0))
result = re.sub(r'(<script type=\"application/ld\+json\">.*?</script>)', fix_jsonld, content, flags=re.DOTALL)
if result != content:
    open('$f', 'w').write(result)
    print('fixed')
else:
    print('clean')
" 2>/dev/null && ok "Schema URLs in $f" || fix "Skipped $f (no python3 or no change)"
  fi
done

# ── 5. Fix missing H1 on obs-calc.html ───────────────────────────────────────
echo -e "\n${BOLD}[5] FIX missing H1 on obs-calc.html${NC}"
if [ -f "obs-calc.html" ]; then
  H1=$(grep -c '<h1' obs-calc.html)
  if [ "$H1" -eq 0 ]; then
    # Find first h2 and check what it says
    FIRST_H2=$(grep -oP '(?<=<h2[^>]*>)[^<]+' obs-calc.html | head -1)
    fix "No H1 found. First H2: '$FIRST_H2'"
    fix "Changing first <h2 to <h1 in obs-calc.html"
    # Replace only the FIRST h2 opening tag with h1
    sed -i '0,/<h2/{s/<h2\([^>]*\)>/<h1\1>/}' obs-calc.html
    sed -i '0,/<\/h2>/{s/<\/h2>/<\/h1>/}' obs-calc.html
    ok "First H2 promoted to H1 in obs-calc.html"
  else
    ok "obs-calc.html already has H1"
  fi
fi

# ── 6. Verify all canonicals now clean ───────────────────────────────────────
echo -e "\n${BOLD}[6] VERIFICATION${NC}"
CANON_HTML=$(grep -rl 'canonical.*\.html' . --include="*.html" | wc -l)
OG_HTML=$(grep -rl 'og:url.*\.html' . --include="*.html" | wc -l)
SCHEMA_HTML=$(grep -rl '"item":.*\.html\|"url":.*\.html' . --include="*.html" | wc -l)

[ "$CANON_HTML" -eq 0 ] && ok "Canonical tags: all clean" || err "$CANON_HTML files still have .html in canonical"
[ "$OG_HTML" -eq 0 ]    && ok "og:url tags: all clean"    || err "$OG_HTML files still have .html in og:url"
[ "$SCHEMA_HTML" -eq 0 ] && ok "Schema URLs: all clean"   || fix "$SCHEMA_HTML files may still have .html in schema (check manually)"

# ── 7. Git commit and push ────────────────────────────────────────────────────
echo -e "\n${BOLD}[7] GIT COMMIT & PUSH${NC}"
git add -A
git status --short

echo -e "\n${YEL}Ready to commit. Press Enter to push, or Ctrl+C to cancel.${NC}"
read -r

git commit -m "SEO fix: og:url .html → clean URLs, fix canonicals, remove duplicate, fix H1"
git push

echo -e "\n${BOLD}${GRN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${GRN}  Done. GitHub Pages will rebuild in ~2 minutes.${NC}"
echo -e "${BOLD}${GRN}  Then re-run audit.sh to verify.${NC}"
echo -e "${BOLD}${GRN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
