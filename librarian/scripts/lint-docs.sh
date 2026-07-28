#!/usr/bin/env bash
set -euo pipefail

# Docs health audit — lint-docs.sh
# Run from repo root: .opencode/skills/librarian/scripts/lint-docs.sh

DOCS_DIR="docs"
INDEX_FILE="${DOCS_DIR}/INDEX.md"
ERRORS=0
WARNINGS=0

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
yellow(){ printf '\033[33m%s\033[0m\n' "$*"; }

check() {
  if [ "$2" -eq 0 ]; then
    green "  ✅ $1"
  else
    red "  ❌ $1"
    ERRORS=$((ERRORS + 1))
  fi
}

warn() {
  yellow "  ⚠️  $1"
  WARNINGS=$((WARNINGS + 1))
}

echo "━━━ Docs Health Audit ━━━"
echo ""

# --- 1. Front matter compliance ---
echo "1. Front matter compliance"
MISSING_FM=0
NO_TITLE=0
NO_STATUS=0
NO_REVIEWED=0

while IFS= read -r file; do
  rel="${file#${DOCS_DIR}/}"
  # Skip CONVENTIONS.md itself and INDEX.md
  [ "$rel" = "CONVENTIONS.md" ] && continue
  [ "$rel" = "INDEX.md" ] && continue

  content=$(<"$file")

  # Check for front matter (starts with ---)
  if ! echo "$content" | head -1 | grep -q '^---$'; then
    warn "$rel — no front matter"
    MISSING_FM=$((MISSING_FM + 1))
    continue
  fi

  # Extract front matter block
  fm=$(echo "$content" | sed -n '/^---$/,/^---$/p' | sed '1d;$d')

  if ! echo "$fm" | grep -q '^title:'; then
    warn "$rel — missing title"
    NO_TITLE=$((NO_TITLE + 1))
  fi
  if ! echo "$fm" | grep -q '^status:'; then
    warn "$rel — missing status"
    NO_STATUS=$((NO_STATUS + 1))
  fi
  if ! echo "$fm" | grep -q '^reviewed:'; then
    warn "$rel — missing reviewed"
    NO_REVIEWED=$((NO_REVIEWED + 1))
  fi
done < <(find "${DOCS_DIR}" -name '*.md' -not -path '*/node_modules/*' -not -path '*/.opencode/*' | sort)

total=$(find "${DOCS_DIR}" -name '*.md' -not -path '*/node_modules/*' -not -path '*/.opencode/*' | wc -l)
check "Front matter present on ${total} .md files (excl. CONVENTIONS.md, INDEX.md)" $((MISSING_FM == 0 ? 1 : 0))

# --- 2. Stale detection ---
echo ""
echo "2. Stale detection"
STALE_COUNT=0
while IFS= read -r file; do
  content=$(<"$file")
  if echo "$content" | grep -q '^status: stale'; then
    rel="${file#${DOCS_DIR}/}"
    warn "$rel — status: stale"
    STALE_COUNT=$((STALE_COUNT + 1))
  fi
done < <(find "${DOCS_DIR}" -name '*.md' -not -path '*/node_modules/*' | sort)

# Also check for reviewed > 12 months ago
ONE_YEAR_AGO=$(date -d '12 months ago' '+%Y-%m-%d' 2>/dev/null || date -v -12m '+%Y-%m-%d' 2>/dev/null || echo "skip")
if [ "$ONE_YEAR_AGO" != "skip" ]; then
  while IFS= read -r file; do
    content=$(<"$file")
    reviewed=$(echo "$content" | grep '^reviewed:' | sed 's/^reviewed: *//' | head -1)
    if [ -n "$reviewed" ] && [ "$reviewed" \< "$ONE_YEAR_AGO" ]; then
      rel="${file#${DOCS_DIR}/}"
      warn "$rel — reviewed $reviewed (over 12 months ago)"
    fi
  done < <(find "${DOCS_DIR}" -name '*.md' -not -path '*/node_modules/*' | sort)
fi

check "No stale docs found" $((STALE_COUNT == 0 ? 1 : 0))

# --- 3. INDEX.md integrity ---
echo ""
echo "3. INDEX.md integrity"
if [ -f "$INDEX_FILE" ]; then
  # Find files not in INDEX.md
  MISSING_FROM_INDEX=0
  while IFS= read -r file; do
    rel="${file#${DOCS_DIR}/}"
    [ "$rel" = "INDEX.md" ] && continue
    if ! grep -qF "$rel" "$INDEX_FILE" 2>/dev/null; then
      warn "$rel — not listed in INDEX.md"
      MISSING_FROM_INDEX=$((MISSING_FROM_INDEX + 1))
    fi
  done < <(find "${DOCS_DIR}" -name '*.md' -not -path '*/node_modules/*' -not -path '*/.opencode/*' | sort)

  # Find INDEX.md entries pointing to missing files
  ORPHAN_ENTRIES=0
  while IFS= read -r link; do
    # Extract relative path from markdown link [...](./path)
    target=$(echo "$link" | sed -n 's/.*\](\.\/\([^)]*\))).*/\1/p' | sed 's/.*\](\.\/\([^)]*\))/\1/' | head -1)
    if [ -n "$target" ]; then
      # Remove any trailing ): from malformed links
      target="${target%)}"
      if [ ! -f "${DOCS_DIR}/$target" ] && [[ "$target" != *"#"* ]]; then
        warn "INDEX.md references missing file: $target"
        ORPHAN_ENTRIES=$((ORPHAN_ENTRIES + 1))
      fi
    fi
  done < <(grep -oP '\]\(\./[^)]+\)' "$INDEX_FILE" | sed 's/\]\(\.\// /' | sed 's/)$//' | awk '{print $2}' | sort -u)

  check "All files listed in INDEX.md" $((MISSING_FROM_INDEX == 0 ? 1 : 0))
  check "No orphan INDEX.md entries" $((ORPHAN_ENTRIES == 0 ? 1 : 0))
else
  warn "INDEX.md not found at $INDEX_FILE"
fi

# --- 4. Marker consistency ---
echo ""
echo "4. Marker consistency"
# Find ⏳ markers and check if they have BD issue refs nearby
PENDING_MARKERS=$(grep -r '⏳' "${DOCS_DIR}" --include='*.md' -l --exclude='*/node_modules/*' 2>/dev/null | grep -v 'PENDING.md' | wc -l)
if [ "$PENDING_MARKERS" -gt 0 ]; then
  warn "$PENDING_MARKERS files have ⏳ markers outside PENDING.md (may need PENDING.md sync)"
fi

# --- 5. BD issue cross-references ---
echo ""
echo "5. BD issue cross-references"
BD_REF_FILES=$(grep -rl 'soralia-village-' "${DOCS_DIR}" --include='*.md' --exclude='*/node_modules/*' 2>/dev/null | sort | wc -l)
if [ "$BD_REF_FILES" -gt 0 ]; then
  green "  ✅ $BD_REF_FILES files reference BD issues"
else
  warn "No BD issue references found in docs/"
fi

# --- Summary ---
echo ""
echo "━━━ Summary ━━━"
if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
  green "✨ All clean!"
elif [ "$ERRORS" -eq 0 ]; then
  yellow "⚠️  $WARNINGS warnings, 0 errors"
else
  red "❌ $ERRORS errors, $WARNINGS warnings"
fi

exit $ERRORS
