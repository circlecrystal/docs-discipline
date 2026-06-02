#!/usr/bin/env bash
# docs-discipline drift-check
#
# Heuristic detection of documentation drift. Reports candidates only — does not auto-fix.
# Exit codes: 0 = no drift, 1 = drift candidates found, 2 = setup error.
#
# Heuristics (project-agnostic):
#   1. Broken relative links in markdown
#   2. last_updated timestamps lagging git log by > N days
#   3. Orphan markdown files (no other doc references them)
#   4. Same H1 title used in multiple files (potential SSOT violation)
#
# Usage: drift-check.sh [ROOT_DIR]
# Env:   DOCS_DISCIPLINE_STALE_DAYS (default 30)

set -uo pipefail

ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$ROOT" || { echo "Cannot cd to $ROOT" >&2; exit 2; }

STALE_DAYS="${DOCS_DISCIPLINE_STALE_DAYS:-30}"
DRIFT=0

MD=()
if git rev-parse --git-dir >/dev/null 2>&1; then
  # Git-aware: respect the project's .gitignore. Includes tracked + untracked-but-not-ignored.
  while IFS= read -r line; do
    MD+=("./$line")
  done < <(git ls-files '*.md' --cached --others --exclude-standard 2>/dev/null | LC_ALL=C sort)
else
  # Not a git repo — fall back to find with a minimal set of common excludes.
  while IFS= read -r line; do
    MD+=("$line")
  done < <(find . -type f -name '*.md' \
    -not -path '*/node_modules/*' \
    -not -path '*/.git/*' \
    -not -path '*/build/*' \
    -not -path '*/dist/*' \
    -not -path '*/.venv/*' \
    -not -path '*/__pycache__/*' 2>/dev/null | LC_ALL=C sort)
fi

if [ "${#MD[@]}" -eq 0 ]; then
  echo "No markdown files found under $ROOT"
  exit 0
fi

echo "=== docs-discipline drift-check ==="
echo "Root:    $ROOT"
echo "Scanned: ${#MD[@]} markdown files"
echo ""

# ----- Heuristic 1: broken relative links -----
echo "[1/4] Broken relative links"
BROKEN_TMP=$(mktemp)
for f in "${MD[@]}"; do
  dir=$(dirname "$f")
  while IFS= read -r link; do
    [ -z "$link" ] && continue
    case "$link" in
      http://*|https://*|mailto:*|tel:*|ftp://*|\#*|\~*) continue ;;
    esac
    target="${link%%#*}"
    target="${target%%\?*}"
    [ -z "$target" ] && continue
    case "$target" in
      */*|*.*) ;;
      *) continue ;;
    esac
    if [ "${target:0:1}" = "/" ]; then
      full=".$target"
    else
      full="$dir/$target"
    fi
    if [ ! -e "$full" ]; then
      printf '  %s -> %s\n' "$f" "$link" >> "$BROKEN_TMP"
    fi
  done < <(grep -oE '\[[^]]+\]\([^)]+\)' "$f" 2>/dev/null | sed -E 's/^\[[^]]+\]\(([^)]+)\)$/\1/')
done
BROKEN_COUNT=$(wc -l < "$BROKEN_TMP" | tr -d ' ')
[ "$BROKEN_COUNT" -gt 0 ] && cat "$BROKEN_TMP"
rm -f "$BROKEN_TMP"
echo "  Found: $BROKEN_COUNT"
[ "$BROKEN_COUNT" -gt 0 ] && DRIFT=1
echo ""

# ----- Heuristic 2: stale timestamps -----
echo "[2/4] last_updated lagging git log by > $STALE_DAYS days"
STALE_COUNT=0
for f in "${MD[@]}"; do
  TS=$(grep -m1 -oE 'last_updated[^0-9]*[0-9]{4}-[0-9]{2}-[0-9]{2}' "$f" 2>/dev/null | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}')
  [ -z "$TS" ] && continue
  GIT_TS=$(git log -1 --format=%cs -- "$f" 2>/dev/null)
  [ -z "$GIT_TS" ] && continue
  if date -j -f "%Y-%m-%d" "$TS" +%s >/dev/null 2>&1; then
    TS_EPOCH=$(date -j -f "%Y-%m-%d" "$TS" +%s 2>/dev/null) || continue
    GIT_EPOCH=$(date -j -f "%Y-%m-%d" "$GIT_TS" +%s 2>/dev/null) || continue
  else
    TS_EPOCH=$(date -d "$TS" +%s 2>/dev/null) || continue
    GIT_EPOCH=$(date -d "$GIT_TS" +%s 2>/dev/null) || continue
  fi
  DIFF=$(( (GIT_EPOCH - TS_EPOCH) / 86400 ))
  if [ "$DIFF" -gt "$STALE_DAYS" ]; then
    echo "  $f: last_updated=$TS, git=$GIT_TS, lag=${DIFF}d"
    STALE_COUNT=$((STALE_COUNT + 1))
  fi
done
echo "  Found: $STALE_COUNT"
[ "$STALE_COUNT" -gt 0 ] && DRIFT=1
echo ""

# ----- Heuristic 3: orphan docs -----
echo "[3/4] Orphan markdown files (no other doc references them)"
ORPHAN_COUNT=0
for f in "${MD[@]}"; do
  basename=$(basename "$f")
  case "$basename" in
    README.md|CLAUDE.md|index.md|LICENSE.md|CHANGELOG.md|CONTRIBUTING.md) continue ;;
  esac
  HITS=0
  for g in "${MD[@]}"; do
    [ "$g" = "$f" ] && continue
    if grep -q -F "$basename" "$g" 2>/dev/null; then
      HITS=1
      break
    fi
  done
  if [ "$HITS" -eq 0 ]; then
    echo "  $f"
    ORPHAN_COUNT=$((ORPHAN_COUNT + 1))
  fi
done
echo "  Found: $ORPHAN_COUNT"
[ "$ORPHAN_COUNT" -gt 0 ] && DRIFT=1
echo ""

# ----- Heuristic 4: duplicate H1 titles -----
echo "[4/4] Same H1 title in multiple files"
H1_TMP=$(mktemp)
for f in "${MD[@]}"; do
  H1=$(grep -m1 -E '^# ' "$f" 2>/dev/null | sed -E 's/^# +//')
  [ -z "$H1" ] && continue
  printf '%s\t%s\n' "$H1" "$f" >> "$H1_TMP"
done
DUP_H1=$(awk -F '\t' '{print $1}' "$H1_TMP" | LC_ALL=C sort | LC_ALL=C uniq -d)
DUP_COUNT=0
if [ -n "$DUP_H1" ]; then
  while IFS= read -r title; do
    echo "  '$title' used by:"
    awk -F '\t' -v t="$title" '$1 == t {print "    " $2}' "$H1_TMP"
    DUP_COUNT=$((DUP_COUNT + 1))
  done <<< "$DUP_H1"
fi
rm -f "$H1_TMP"
echo "  Found: $DUP_COUNT duplicated H1 title(s)"
[ "$DUP_COUNT" -gt 0 ] && DRIFT=1
echo ""

# ----- Summary -----
echo "=== Summary ==="
if [ "$DRIFT" -eq 0 ]; then
  echo "No drift detected."
else
  echo "Drift candidates detected. Review above; decide what's drift vs. intentional."
fi
exit "$DRIFT"
