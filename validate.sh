#!/usr/bin/env bash
# validate.sh — check for unfilled {{PLACEHOLDER}} values in content/ and examples/
#
# Usage:
#   ./validate.sh                    # check content/ only (default)
#   ./validate.sh --dir examples/eargrade   # check a specific directory
#   ./validate.sh --all              # check content/ and all examples/
#   ./validate.sh --help

set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

ok()   { echo -e "${GREEN}✓${RESET}  $*"; }
info() { echo -e "${CYAN}→${RESET}  $*"; }
warn() { echo -e "${YELLOW}!${RESET}  $*"; }
err()  { echo -e "${RED}✗${RESET}  $*" >&2; }

# ── Paths ─────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Argument parsing ──────────────────────────────────────────────────────────

DIRS=()
CHECK_ALL=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)     DIRS+=("$2"); shift 2 ;;
    --all)     CHECK_ALL=true; shift ;;
    --help|-h)
      cat <<EOF
Usage: ./validate.sh [OPTIONS]

Checks for unfilled {{PLACEHOLDER}} values in markdown files.

Options:
  --dir <path>   Check a specific directory (can be repeated)
  --all          Check content/ and all examples/
  --help         Show this help

Examples:
  ./validate.sh                         # check content/ only
  ./validate.sh --dir examples/eargrade # check eargrade example
  ./validate.sh --all                   # check everything

Exit codes:
  0 — no unfilled placeholders found
  1 — unfilled placeholders found (check output for details)
EOF
      exit 0 ;;
    *) err "Unknown argument: $1. Run with --help for usage."; exit 1 ;;
  esac
done

# Default: check content/
if [[ $CHECK_ALL == false && ${#DIRS[@]} -eq 0 ]]; then
  DIRS=("$SCRIPT_DIR/content")
fi

# --all: content/ + all examples/*/
if $CHECK_ALL; then
  DIRS=("$SCRIPT_DIR/content")
  while IFS= read -r -d '' d; do
    DIRS+=("$d")
  done < <(find "$SCRIPT_DIR/examples" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
fi

# ── Validation ────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}validate.sh — checking for unfilled placeholders${RESET}"
echo ""

total_files=0
total_hits=0
any_found=false

for dir in "${DIRS[@]}"; do
  if [[ ! -d "$dir" ]]; then
    warn "Directory not found, skipping: $dir"
    continue
  fi

  dir_label="${dir#"$SCRIPT_DIR/"}"
  dir_hits=0
  dir_files=0

  while IFS= read -r -d '' file; do
    (( dir_files++ )) || true

    # Find lines with {{...}} patterns, excluding comment lines that show examples
    # A comment line starts with optional whitespace then <!--
    hits=$(grep -n '{{[A-Z_][A-Z_0-9]*}}' "$file" 2>/dev/null | grep -v '<!--' || true)

    if [[ -n "$hits" ]]; then
      any_found=true
      (( dir_hits++ )) || true
      file_label="${file#"$SCRIPT_DIR/"}"
      echo -e "  ${RED}✗${RESET}  $file_label"
      while IFS= read -r line; do
        lineno="${line%%:*}"
        content="${line#*:}"
        # Extract just the placeholder names for a clean summary
        placeholders=$(echo "$content" | grep -o '{{[A-Z_][A-Z_0-9]*}}' | sort -u | tr '\n' ' ')
        printf "       line %-4s  %s\n" "$lineno" "$placeholders"
      done <<< "$hits"
      echo ""
    fi
  done < <(find "$dir" -name "*.md" -not -path "*/node_modules/*" -print0 2>/dev/null)

  (( total_files += dir_files )) || true
  (( total_hits += dir_hits )) || true

  if [[ $dir_hits -eq 0 ]]; then
    ok "$dir_label — $dir_files files, no unfilled placeholders"
  else
    warn "$dir_label — $dir_hits / $dir_files files have unfilled placeholders"
  fi
done

echo ""

# ── Summary ───────────────────────────────────────────────────────────────────

if $any_found; then
  echo -e "${BOLD}${RED}Found unfilled placeholders.${RESET}"
  echo ""
  echo "These files are not ready to install. Fill in all {{PLACEHOLDER}} values"
  echo "before running install.sh. See examples/eargrade/ for filled-in references."
  echo ""
  exit 1
else
  echo -e "${BOLD}${GREEN}All clean.${RESET} No unfilled placeholders found."
  echo ""
  exit 0
fi