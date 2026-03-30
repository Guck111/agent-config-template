#!/usr/bin/env bash
# adapters/claude-code/convert.sh
#
# Converts content/ into Claude Code project config.
#
# Usage (run from your project root):
#   /path/to/agent-config-template/adapters/claude-code/convert.sh
#   /path/to/agent-config-template/adapters/claude-code/convert.sh --source /path/to/content
#
# Output: .claude/agents/ and CLAUDE.md in the current directory.
# Existing files are backed up to .claude/agents.bak/ before overwrite.

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
TEMPLATE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROJECT_ROOT="$(pwd)"

# Allow --source override
CONTENT_DIR="$TEMPLATE_ROOT/content"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --source) CONTENT_DIR="$2"; shift 2 ;;
    --help|-h)
      echo "Usage: $0 [--source /path/to/content]"
      echo "Run from your project root. Writes to .claude/agents/ and CLAUDE.md."
      exit 0 ;;
    *) die "Unknown argument: $1" ;;
  esac
done

[[ -d "$CONTENT_DIR" ]] || die "content/ directory not found at: $CONTENT_DIR"

AGENTS_DIR="$PROJECT_ROOT/.claude/agents"
CONTEXT_DIR="$PROJECT_ROOT/.claude/context"
CLAUDE_MD="$PROJECT_ROOT/CLAUDE.md"

# ── Detect project name ───────────────────────────────────────────────────────

PROJECT_NAME="$(basename "$PROJECT_ROOT")"
echo ""
echo -e "${BOLD}agent-config-template → Claude Code${RESET}"
echo -e "Project root : $PROJECT_ROOT"
echo -e "Content from : $CONTENT_DIR"
echo ""

# ── Backup existing .claude/agents if present ─────────────────────────────────

if [[ -d "$AGENTS_DIR" ]]; then
  BAK="$PROJECT_ROOT/.claude/agents.bak.$(date +%Y%m%d-%H%M%S)"
  warn "Existing .claude/agents/ found — backing up to $(basename "$BAK")"
  cp -r "$AGENTS_DIR" "$BAK"
fi

# ── Create directories ────────────────────────────────────────────────────────

mkdir -p "$AGENTS_DIR"
mkdir -p "$AGENTS_DIR/workflows"
mkdir -p "$CONTEXT_DIR"

# ── Copy always-on rules ──────────────────────────────────────────────────────

ALWAYS_ON=(role.md instructions.md architecture.md skills.md)

for file in "${ALWAYS_ON[@]}"; do
  src="$CONTENT_DIR/$file"
  dst="$AGENTS_DIR/$file"
  if [[ -f "$src" ]]; then
    cp "$src" "$dst"
    ok "agents/$file"
  else
    warn "Missing: content/$file — skipped"
  fi
done

# ── Copy domain agents (agent-*.md) ──────────────────────────────────────────

found_agents=0
while IFS= read -r -d '' src; do
  filename="$(basename "$src")"
  dst="$AGENTS_DIR/$filename"
  cp "$src" "$dst"
  ok "agents/$filename"
  (( found_agents++ )) || true
done < <(find "$CONTENT_DIR" -maxdepth 1 -name "agent-*.md" -print0 2>/dev/null)

if [[ $found_agents -eq 0 ]]; then
  warn "No agent-*.md files found in content/ — add domain agents when ready"
fi

# ── Copy workflows ────────────────────────────────────────────────────────────

if [[ -d "$CONTENT_DIR/workflows" ]]; then
  while IFS= read -r -d '' src; do
    filename="$(basename "$src")"
    dst="$AGENTS_DIR/workflows/$filename"
    cp "$src" "$dst"
    ok "agents/workflows/$filename"
  done < <(find "$CONTENT_DIR/workflows" -name "*.md" -print0 2>/dev/null)
else
  warn "No content/workflows/ directory found — skipped"
fi

# ── Copy context ──────────────────────────────────────────────────────────────

if [[ -d "$CONTENT_DIR/context" ]]; then
  while IFS= read -r -d '' src; do
    filename="$(basename "$src")"
    dst="$CONTEXT_DIR/$filename"
    cp "$src" "$dst"
    ok "context/$filename"
  done < <(find "$CONTENT_DIR/context" -name "*.md" -print0 2>/dev/null)
else
  warn "No content/context/ directory found — skipped"
fi

# ── Generate or update CLAUDE.md ──────────────────────────────────────────────

generate_claude_md() {
  # Build @-import list from what was actually written
  local imports=""

  for file in "${ALWAYS_ON[@]}"; do
    [[ -f "$AGENTS_DIR/$file" ]] && imports+="@.claude/agents/$file\n"
  done

  while IFS= read -r -d '' f; do
    filename="$(basename "$f")"
    imports+="@.claude/agents/$filename\n"
  done < <(find "$AGENTS_DIR" -maxdepth 1 -name "agent-*.md" -print0 2>/dev/null)

  while IFS= read -r -d '' f; do
    filename="$(basename "$f")"
    imports+="@.claude/agents/workflows/$filename\n"
  done < <(find "$AGENTS_DIR/workflows" -name "*.md" -print0 2>/dev/null)

  while IFS= read -r -d '' f; do
    filename="$(basename "$f")"
    imports+="@.claude/context/$filename\n"
  done < <(find "$CONTEXT_DIR" -name "*.md" -print0 2>/dev/null)

  cat <<EOF
# ${PROJECT_NAME}

<!-- One-line description of the project. -->
<!-- TODO: fill in project description -->

## Commands

\`\`\`bash
# TODO: add your key commands here
\`\`\`

## Agent context

$(echo -e "$imports")
EOF
}

if [[ -f "$CLAUDE_MD" ]]; then
  warn "CLAUDE.md already exists — not overwriting"
  info "Add these @-imports to your CLAUDE.md manually:"
  echo ""
  for file in "${ALWAYS_ON[@]}"; do
    [[ -f "$AGENTS_DIR/$file" ]] && echo "  @.claude/agents/$file"
  done
  find "$AGENTS_DIR" -maxdepth 1 -name "agent-*.md" 2>/dev/null \
    | sort | while read -r f; do echo "  @.claude/agents/$(basename "$f")"; done
  find "$AGENTS_DIR/workflows" -name "*.md" 2>/dev/null \
    | sort | while read -r f; do echo "  @.claude/agents/workflows/$(basename "$f")"; done
  find "$CONTEXT_DIR" -name "*.md" 2>/dev/null \
    | sort | while read -r f; do echo "  @.claude/context/$(basename "$f")"; done
  echo ""
else
  generate_claude_md > "$CLAUDE_MD"
  ok "CLAUDE.md (generated — fill in project description and commands)"
fi

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}Done.${RESET}"
echo ""
echo "Next steps:"
echo "  1. Fill in {{PLACEHOLDER}} values in .claude/agents/*.md"
echo "  2. Add your project description and commands to CLAUDE.md"
echo "  3. Run: claude   (Claude Code will pick up the config automatically)"
echo ""
echo "Tip: after 10+ sessions, run skill-workshop to capture recurring patterns:"
echo "  https://github.com/grayodesa/skill-workshop"
echo ""
