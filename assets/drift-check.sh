#!/usr/bin/env bash
# docs-discipline drift-check
#
# Heuristic detection of documentation drift. Reports candidates only — does not auto-fix.
# Exit codes: 0 = no drift, 1 = drift candidates found, 2 = setup error.
#
# Heuristics:
#   1. Broken relative links in markdown             (project-agnostic)
#   2. last_updated timestamps lagging git log       (project-agnostic)
#   3. Orphan markdown files (no other doc refs)     (project-agnostic)
#   4. Same H1 title used in multiple files          (project-agnostic)
#   5. B-layer bloat: oversized / impl-detail leak   (A/B-aware: scans only B)
#
# Heuristic 5 is A/B-aware: it scans ONLY the project's B-layer files (declared
# in CLAUDE.md, or heuristically discovered) so that large, legitimately frozen
# A-layer artifacts (spike reports, ADRs, handoffs) are never flagged as bloat.
#
# Usage: drift-check.sh [ROOT_DIR]
# Env:   DOCS_DISCIPLINE_STALE_DAYS  (default 30)
#        DOCS_DISCIPLINE_B_MAX_LINES (default 250)  B-layer per-file line budget
#        DOCS_DISCIPLINE_B_MAX_IMPL  (default 12)   B-layer impl-token budget

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
echo "[1/5] Broken relative links"
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
echo "[2/5] last_updated lagging git log by > $STALE_DAYS days"
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
echo "[3/5] Orphan markdown files (no other doc references them)"
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
echo "[4/5] Same H1 title in multiple files"
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

# ----- Heuristic 5: B-layer bloat (A/B-aware) -----
echo "[5/5] B-layer bloat (oversized / implementation-detail leak)"
B_MAX_LINES="${DOCS_DISCIPLINE_B_MAX_LINES:-250}"
B_MAX_IMPL="${DOCS_DISCIPLINE_B_MAX_IMPL:-12}"
B_FALLBACK=0

# Discover the B-layer file set. Prefer CLAUDE.md's declaration; else heuristics.
# Same B-set logic as review-procedure.md step 5(b), kept in sync.
B_RAW=()
if [ -f "CLAUDE.md" ]; then
  while IFS= read -r p; do
    [ -n "$p" ] && B_RAW+=("$p")
  done < <(awk '
      /^#+[[:space:]].*[Ww]here this project.?s B layer lives/ {grab=1; next}
      grab && /^#{1,4}[[:space:]]/ {grab=0}
      grab {print}
    ' "CLAUDE.md" \
    | grep -oE '\]\([^)]+\)|`[^`]+`' \
    | sed -E 's/^\]\(//; s/\)$//; s/^`//; s/`$//; s/#.*$//; s/\?.*$//' \
    | grep -E '\.(md|markdown)$')
fi

if [ "${#B_RAW[@]}" -eq 0 ]; then
  B_FALLBACK=1
  for cand in README.md docs/README.md STATUS.md ROADMAP.md; do
    [ -f "$cand" ] && B_RAW+=("$cand")
  done
  for f in "${MD[@]}"; do
    if head -n 50 "$f" 2>/dev/null | grep -qiE 'current state|snapshot|status|roadmap'; then
      B_RAW+=("${f#./}")
    fi
  done
fi

# Normalize (strip ./), dedupe.
B_FILES=()
if [ "${#B_RAW[@]}" -gt 0 ]; then
  while IFS= read -r bf; do
    [ -n "$bf" ] && B_FILES+=("$bf")
  done < <(printf '%s\n' "${B_RAW[@]}" | sed -E 's#^\./##' | LC_ALL=C sort -u)
fi

BLOAT_COUNT=0
if [ "${#B_FILES[@]}" -eq 0 ]; then
  echo "  No B-layer files identified (declare them in CLAUDE.md to enable this check)."
else
  [ "$B_FALLBACK" -eq 1 ] && echo "  (heuristic fallback — no B-layer map in CLAUDE.md; accuracy reduced)"
  for f in "${B_FILES[@]}"; do
    [ -f "$f" ] || continue
    LINES=$(wc -l < "$f" | tr -d ' ')
    IMPL=$(grep -oE '#[0-9a-fA-F]{6}|[0-9a-f]{7,40}' "$f" 2>/dev/null | wc -l | tr -d ' ')
    FLAGS=""
    [ "$LINES" -gt "$B_MAX_LINES" ] && FLAGS="oversized=${LINES}L"
    if [ "$IMPL" -gt "$B_MAX_IMPL" ]; then
      [ -n "$FLAGS" ] && FLAGS="$FLAGS, "
      FLAGS="${FLAGS}impl-leak=${IMPL}tok"
    fi
    if [ -n "$FLAGS" ]; then
      echo "  $f: $FLAGS"
      BLOAT_COUNT=$((BLOAT_COUNT + 1))
    fi
  done
fi
echo "  Found: $BLOAT_COUNT"
[ "$BLOAT_COUNT" -gt 0 ] && DRIFT=1
echo ""

# ----- Summary -----
echo "=== Summary ==="
if [ "$DRIFT" -eq 0 ]; then
  echo "No drift detected."
else
  echo "Drift candidates detected. Review above; decide what's drift vs. intentional."
fi
exit "$DRIFT"
