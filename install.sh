#!/usr/bin/env bash
# install.sh — agent-config-template interactive installer
#
# Detects installed AI coding tools and runs the appropriate adapter.
# Run from the project root where you want to install the agent config.
#
# Usage:
#   ./install.sh                    # auto-detect + interactive
#   ./install.sh --tool claude-code # specific tool, no prompt
#   ./install.sh --tool antigravity
#   ./install.sh --source /path/to/filled-content  # custom content dir
#   ./install.sh --list             # show detected tools and exit

set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

ok()   { echo -e "${GREEN}✓${RESET}  $*"; }
info() { echo -e "${CYAN}→${RESET}  $*"; }
warn() { echo -e "${YELLOW}!${RESET}  $*"; }
err()  { echo -e "${RED}✗${RESET}  $*" >&2; }
die()  { err "$*"; exit 1; }

# ── Paths ─────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADAPTERS_DIR="$SCRIPT_DIR/adapters"
CONTENT_DIR="$SCRIPT_DIR/content"

# ── Argument parsing ──────────────────────────────────────────────────────────

TARGET_TOOL=""
SOURCE_DIR="$CONTENT_DIR"
LIST_ONLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tool)    TARGET_TOOL="$2"; shift 2 ;;
    --source)  SOURCE_DIR="$2"; shift 2 ;;
    --list)    LIST_ONLY=true; shift ;;
    --help|-h)
      cat <<EOF
Usage: ./install.sh [OPTIONS]

Options:
  --tool <name>      Target a specific tool (claude-code, antigravity)
  --source <path>    Use an alternative content directory (default: ./content)
  --list             Show detected tools and exit
  --help             Show this help

Examples:
  ./install.sh                         # interactive: pick from detected tools
  ./install.sh --tool claude-code      # install for Claude Code only
  ./install.sh --tool antigravity      # install for Antigravity only

  # Install from a filled example (e.g. eargrade):
  ./install.sh --source examples/eargrade --tool claude-code

Supported tools: claude-code, antigravity
EOF
      exit 0 ;;
    *) die "Unknown argument: $1. Run with --help for usage." ;;
  esac
done

[[ -d "$SOURCE_DIR" ]] || die "Content directory not found: $SOURCE_DIR"

# ── Tool detection ────────────────────────────────────────────────────────────

ALL_TOOLS=(claude-code antigravity)

detect_claude_code() {
  command -v claude &>/dev/null || [[ -d "${HOME}/.claude" ]]
}

detect_antigravity() {
  [[ -d "${HOME}/.gemini/antigravity" ]] \
    || command -v antigravity &>/dev/null \
    || command -v gemini &>/dev/null
}

declare -A TOOL_DETECTED=()
declare -A TOOL_LABEL=(
  [claude-code]="Claude Code  (~/.claude/agents/)"
  [antigravity]="Antigravity  (~/.gemini/antigravity/skills/)"
)

for tool in "${ALL_TOOLS[@]}"; do
  case "$tool" in
    claude-code)  detect_claude_code  && TOOL_DETECTED[$tool]=1 || TOOL_DETECTED[$tool]=0 ;;
    antigravity)  detect_antigravity  && TOOL_DETECTED[$tool]=1 || TOOL_DETECTED[$tool]=0 ;;
  esac
done

# ── --list mode ───────────────────────────────────────────────────────────────

if $LIST_ONLY; then
  echo ""
  echo -e "${BOLD}Detected tools:${RESET}"
  for tool in "${ALL_TOOLS[@]}"; do
    if [[ "${TOOL_DETECTED[$tool]}" == "1" ]]; then
      echo -e "  ${GREEN}[*]${RESET} ${TOOL_LABEL[$tool]}"
    else
      echo -e "  ${YELLOW}[ ]${RESET} ${TOOL_LABEL[$tool]}"
    fi
  done
  echo ""
  exit 0
fi

# ── Header ────────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║     agent-config-template installer     ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  Project root : $(pwd)"
echo -e "  Content from : $SOURCE_DIR"
echo ""

# ── Adapter runner ────────────────────────────────────────────────────────────

run_adapter() {
  local tool="$1"
  local adapter="$ADAPTERS_DIR/$tool/convert.sh"

  [[ -f "$adapter" ]] || die "Adapter not found: $adapter"
  [[ -x "$adapter" ]] || chmod +x "$adapter"

  bash "$adapter" --source "$SOURCE_DIR"
}

# ── --tool mode (non-interactive) ─────────────────────────────────────────────

if [[ -n "$TARGET_TOOL" ]]; then
  case "$TARGET_TOOL" in
    claude-code|antigravity) run_adapter "$TARGET_TOOL" ;;
    *) die "Unknown tool: $TARGET_TOOL. Supported: claude-code, antigravity" ;;
  esac
  exit 0
fi

# ── Interactive mode ──────────────────────────────────────────────────────────

echo -e "${BOLD}System scan:${RESET}  [*] = detected   [ ] = not found"
echo ""

i=1
declare -A TOOL_INDEX=()
for tool in "${ALL_TOOLS[@]}"; do
  if [[ "${TOOL_DETECTED[$tool]}" == "1" ]]; then
    echo -e "  ${GREEN}[*]${RESET} $i) ${TOOL_LABEL[$tool]}"
  else
    echo -e "  ${YELLOW}[ ]${RESET} $i) ${TOOL_LABEL[$tool]}"
  fi
  TOOL_INDEX[$i]="$tool"
  (( i++ )) || true
done

echo ""
echo -e "Install detected tools [d], choose by number [1-${#ALL_TOOLS[@]}], or all [a]?"
echo -e "Press [q] to quit."
echo ""

# Collect selected tools
SELECTED_TOOLS=()

while true; do
  read -rp "  Choice: " choice
  case "$choice" in
    q|Q)
      echo ""; info "Cancelled."; exit 0 ;;
    a|A)
      SELECTED_TOOLS=("${ALL_TOOLS[@]}"); break ;;
    d|D)
      for tool in "${ALL_TOOLS[@]}"; do
        [[ "${TOOL_DETECTED[$tool]}" == "1" ]] && SELECTED_TOOLS+=("$tool")
      done
      if [[ ${#SELECTED_TOOLS[@]} -eq 0 ]]; then
        warn "No tools detected. Install Claude Code or Antigravity first, or use --tool."
        exit 1
      fi
      break ;;
    [0-9]*)
      if [[ -n "${TOOL_INDEX[$choice]+_}" ]]; then
        SELECTED_TOOLS=("${TOOL_INDEX[$choice]}"); break
      else
        warn "Invalid choice: $choice"
      fi ;;
    *)
      warn "Invalid choice. Use a number, d, a, or q." ;;
  esac
done

echo ""
echo -e "${BOLD}Installing for: ${SELECTED_TOOLS[*]}${RESET}"
echo ""

# ── Run selected adapters ─────────────────────────────────────────────────────

FAILED=()
for tool in "${SELECTED_TOOLS[@]}"; do
  info "Running $tool adapter…"
  if run_adapter "$tool"; then
    ok "$tool — done"
  else
    err "$tool — failed"
    FAILED+=("$tool")
  fi
  echo ""
done

# ── Final summary ─────────────────────────────────────────────────────────────

if [[ ${#FAILED[@]} -eq 0 ]]; then
  echo -e "${BOLD}${GREEN}All done.${RESET}"
else
  echo -e "${BOLD}${RED}Failed:${RESET} ${FAILED[*]}"
  echo "Check output above for details."
  exit 1
fi

echo ""
echo "Next: fill in {{PLACEHOLDER}} values in your content files."
echo "See docs/philosophy.md for the reasoning behind each section."
echo ""
