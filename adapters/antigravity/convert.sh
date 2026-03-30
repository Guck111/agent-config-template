#!/usr/bin/env bash
# adapters/antigravity/convert.sh
#
# Converts content/ into Antigravity skills for Gemini.
#
# Each content file becomes a skill directory:
#   ~/.gemini/antigravity/skills/<project>-<slug>/SKILL.md
#
# Usage (run from your project root):
#   /path/to/agent-config-template/adapters/antigravity/convert.sh
#   /path/to/agent-config-template/adapters/antigravity/convert.sh --source /path/to/content
#   /path/to/agent-config-template/adapters/antigravity/convert.sh --project myapp
#
# Antigravity docs: https://docs.google.com/document/d/e/antigravity

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

CONTENT_DIR="$TEMPLATE_ROOT/content"
PROJECT_NAME="$(basename "$PROJECT_ROOT")"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)  CONTENT_DIR="$2"; shift 2 ;;
    --project) PROJECT_NAME="$2"; shift 2 ;;
    --help|-h)
      echo "Usage: $0 [--source /path/to/content] [--project name]"
      echo "Writes to ~/.gemini/antigravity/skills/<project>-<slug>/SKILL.md"
      exit 0 ;;
    *) die "Unknown argument: $1" ;;
  esac
done

[[ -d "$CONTENT_DIR" ]] || die "content/ directory not found at: $CONTENT_DIR"

SKILLS_BASE="${HOME}/.gemini/antigravity/skills"

# ── Slugify helper ────────────────────────────────────────────────────────────

slugify() {
  echo "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9]/-/g' \
    | sed 's/-\{2,\}/-/g' \
    | sed 's/^-//;s/-$//'
}

PROJECT_SLUG="$(slugify "$PROJECT_NAME")"

echo ""
echo -e "${BOLD}agent-config-template → Antigravity${RESET}"
echo -e "Project      : $PROJECT_NAME (slug: $PROJECT_SLUG)"
echo -e "Content from : $CONTENT_DIR"
echo -e "Skills to    : $SKILLS_BASE"
echo ""

mkdir -p "$SKILLS_BASE"

# ── Skill descriptions ────────────────────────────────────────────────────────
# Maps filename → human description for the SKILL.md frontmatter

declare -A DESCRIPTIONS=(
  [role]="Role definition, philosophy, critical rules and communication style for ${PROJECT_NAME}"
  [instructions]="General development rules for ${PROJECT_NAME}"
  [architecture]="Architectural boundaries and constraints for ${PROJECT_NAME}"
  [skills]="When X → do Y patterns and code examples for ${PROJECT_NAME}"
)

# ── write_skill: wrap a content file as a SKILL.md ───────────────────────────

write_skill() {
  local src="$1"
  local slug="$2"
  local description="$3"

  local skill_dir="$SKILLS_BASE/${PROJECT_SLUG}-${slug}"
  mkdir -p "$skill_dir"

  # Write SKILL.md with Antigravity frontmatter + original content
  {
    printf -- '---\n'
    printf 'name: %s-%s\n' "$PROJECT_SLUG" "$slug"
    printf 'description: %s\n' "$description"
    printf -- '---\n\n'
    cat "$src"
  } > "$skill_dir/SKILL.md"

  ok "${PROJECT_SLUG}-${slug}/SKILL.md"
}

# ── Convert always-on files ───────────────────────────────────────────────────

declare -A ALWAYS_ON_FILES=(
  [role.md]="role"
  [instructions.md]="instructions"
  [architecture.md]="architecture"
  [skills.md]="skills"
)

for filename in "${!ALWAYS_ON_FILES[@]}"; do
  src="$CONTENT_DIR/$filename"
  slug="${ALWAYS_ON_FILES[$filename]}"
  desc="${DESCRIPTIONS[$slug]:-"${PROJECT_NAME} — ${slug}"}"

  if [[ -f "$src" ]]; then
    write_skill "$src" "$slug" "$desc"
  else
    warn "Missing: content/$filename — skipped"
  fi
done

# ── Convert domain agents (agent-*.md) ───────────────────────────────────────

found_agents=0
while IFS= read -r -d '' src; do
  filename="$(basename "$src" .md)"         # e.g. agent-pipeline
  slug="$(slugify "$filename")"             # e.g. agent-pipeline
  domain="${filename#agent-}"               # e.g. pipeline
  desc="${PROJECT_NAME} — ${domain} domain: identity, process, patterns, and success criteria"

  write_skill "$src" "$slug" "$desc"
  (( found_agents++ )) || true
done < <(find "$CONTENT_DIR" -maxdepth 1 -name "agent-*.md" -print0 2>/dev/null)

if [[ $found_agents -eq 0 ]]; then
  warn "No agent-*.md files found in content/ — skipped"
fi

# ── Convert workflows ─────────────────────────────────────────────────────────

if [[ -d "$CONTENT_DIR/workflows" ]]; then
  while IFS= read -r -d '' src; do
    filename="$(basename "$src" .md)"
    slug="workflow-$(slugify "$filename")"
    desc="${PROJECT_NAME} — ${filename} step-by-step workflow"
    write_skill "$src" "$slug" "$desc"
  done < <(find "$CONTENT_DIR/workflows" -name "*.md" -print0 2>/dev/null)
else
  warn "No content/workflows/ directory — skipped"
fi

# ── Convert context ───────────────────────────────────────────────────────────

if [[ -d "$CONTENT_DIR/context" ]]; then
  while IFS= read -r -d '' src; do
    filename="$(basename "$src" .md)"
    slug="context-$(slugify "$filename")"
    desc="${PROJECT_NAME} — ${filename}: API contracts, types, schema, commands"
    write_skill "$src" "$slug" "$desc"
  done < <(find "$CONTENT_DIR/context" -name "*.md" -print0 2>/dev/null)
else
  warn "No content/context/ directory — skipped"
fi

# ── List installed skills ─────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}Installed skills:${RESET}"
find "$SKILLS_BASE" -maxdepth 1 -name "${PROJECT_SLUG}-*" -type d \
  | sort \
  | while read -r d; do echo "  $SKILLS_BASE/$(basename "$d")/SKILL.md"; done

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}Done.${RESET}"
echo ""
echo "Next steps:"
echo "  1. Fill in {{PLACEHOLDER}} values in:"
echo "     $SKILLS_BASE/${PROJECT_SLUG}-*/SKILL.md"
echo "  2. Restart Gemini / Antigravity to pick up new skills"
echo "  3. Reference skills in Antigravity by name: ${PROJECT_SLUG}-role, ${PROJECT_SLUG}-skills, etc."
echo ""
echo "To remove all ${PROJECT_NAME} skills:"
echo "  rm -rf $SKILLS_BASE/${PROJECT_SLUG}-*"
echo ""
