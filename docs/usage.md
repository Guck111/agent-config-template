# Usage Guide

This document explains how to set up, fill in, and maintain your agent config
using this template. Three scenarios are covered:

1. **New project** — setting up from scratch
2. **Existing project** — migrating an existing config
3. **Eargrade example** — installing the filled example to see the end result

---

## Before you start

You need one of the supported tools installed:

- **Claude Code** — `npm install -g @anthropic-ai/claude-code`
- **Antigravity** (Gemini) — follow setup at https://github.com/google/antigravity

Clone this template somewhere on your machine (not inside your project):

```bash
git clone https://github.com/arseni/agent-config-template.git ~/agent-config-template
```

---

## Scenario 1: New project

### Step 1 — Run the installer from your project root

```bash
cd ~/projects/my-project
~/agent-config-template/install.sh
```

The installer scans your system and shows a menu:

```
System scan:  [*] = detected   [ ] = not found

  [*] 1) Claude Code  (~/.claude/agents/)
  [ ] 2) Antigravity  (~/.gemini/antigravity/skills/)

Install detected tools [d], choose by number [1-2], or all [a]?
Choice:
```

Press `d` to install for all detected tools, or `1` / `2` for a specific one.

**What happens after you press Enter:**

For Claude Code, the installer creates:
```
your-project/
  .claude/
    agents/
      role.md
      instructions.md
      architecture.md
      skills.md
      agent-DOMAIN.md
      workflows/
        feature-workflow.md
    context/
      reference.md
  CLAUDE.md              ← thin index with @-imports
```

For Antigravity, it creates skill directories in:
```
~/.gemini/antigravity/skills/
  your-project-role/SKILL.md
  your-project-instructions/SKILL.md
  your-project-skills/SKILL.md
  ...
```

### Step 2 — Fill in the placeholders

Open `.claude/agents/role.md` (or the equivalent in your Antigravity skills dir).
Every `{{PLACEHOLDER}}` needs a real value. The comments in each file explain
what to put there and show an Eargrade example.

**Work through the files in this order:**

**1. `role.md`** — the most important file. Takes 20–30 minutes.
   - Replace `{{PROJECT_NAME}}` with your project name
   - Write 4 philosophy principles that reflect real decisions you've made
   - Write critical rules — each with a "why" (concrete failure mode)
   - Set success criteria as runnable commands

**2. `architecture.md`** — your system's main structural split.
   - What are the 2–3 major components?
   - What does each own? What is it forbidden to do?
   - How does data flow between them?

**3. `instructions.md`** — general rules that apply everywhere.
   - Language, typing, build, dependencies, security
   - Only rules you've actually needed to enforce — not generic best practices

**4. `skills.md`** — "when X → do Y" patterns.
   - Start with 3–5 entries covering your most common gotchas
   - Each needs a trigger, correct code, and ideally a wrong-code example
   - Leave the `# ADDING SKILLS OVER TIME` comment — it's a reminder

**5. `agent-DOMAIN.md`** — one per major domain (e.g. `agent-backend.md`, `agent-frontend.md`).
   - Rename from `agent-DOMAIN.md` to your actual domain name
   - Set the `globs:` frontmatter to the path that triggers this agent
   - Write identity grounded in real project history

**6. `workflows/feature-workflow.md`** — rename to match your domain.
   - Identify your 2–3 task types
   - Write the exact step order for each
   - Add "Done when" criteria

**7. `context/reference.md`** — facts the agent needs to look up.
   - Env vars, DB schema, API shapes, key commands
   - Only facts. No rules here.

**8. `CLAUDE.md`** — already generated with `@`-imports. Just add:
   - One-line project description
   - Your most-used commands

**Tip:** `examples/eargrade/` shows every file fully filled in.
Open the template and the example side by side.

### Step 3 — Test it

Open Claude Code in your project:

```bash
cd ~/projects/my-project
claude
```

Ask something domain-specific and check if the agent responds with your
philosophy and rules in mind. If it doesn't know something it should —
that section probably still has placeholders.

You already have an agent config (CLAUDE.md, `.claude/agents/`, or similar).
Before migrating, run the audit checklist to understand what needs fixing:

```bash
# Open the checklist alongside your existing config
open ~/agent-config-template/docs/audit-checklist.md
```

Go through all 9 points. Note which ones fail.

Then decide: **migrate** (start fresh from the template) or **fix in place**
(patch specific issues).

**Migrate — when 5+ checklist points fail:**

```bash
cd ~/projects/existing-project

# Back up your current config first
cp -r .claude/agents/ .claude/agents.bak/
cp CLAUDE.md CLAUDE.md.bak

# Install the template
~/agent-config-template/install.sh --tool claude-code
```

Then fill in placeholders, copying relevant content from your backed-up files.

**Fix in place — when 1–4 points fail:**

Use the checklist fixes directly. Common quick fixes:

```bash
# Fix duplicate frontmatter (Point 4)
grep -n "trigger:" .claude/agents/*.md
# Delete any "trigger:" lines that appear outside the frontmatter block (lines > 5)

# Check for duplication (Point 1)
grep -rl "{{YOUR_KEY_TERM}}" .claude/agents/   # pick any fact that might be duplicated
```

---

## Scenario 3: Install the Eargrade example

Want to see the end result before filling anything in? Install the fully
completed Eargrade config:

```bash
cd ~/projects/audio-english   # or any project directory
~/agent-config-template/install.sh --source ~/agent-config-template/examples/eargrade --tool claude-code
```

This installs real, filled-in files — no placeholders. Good for:
- Understanding what a finished config looks like in practice
- Testing that the installer works on your machine
- Using as a reference while filling in your own project

---

## Maintaining the config over time

### After 10+ sessions — run skill-workshop

Repeated agent mistakes should become skills. skill-workshop finds them:

```bash
# Install once
git clone https://github.com/grayodesa/skill-workshop ~/.skill-workshop
cp ~/.skill-workshop/agents/* ~/.claude/agents/
cp -r ~/.skill-workshop/skills/* ~/.claude/skills/

# Run in Claude Code from your project directory
/skill-workshop
```

Review the candidates. Score 60+ with 2+ sessions → add to `skills.md`.

### After major tech changes — re-run the audit

New library, architecture change, migrated a service:

```bash
open ~/agent-config-template/docs/audit-checklist.md
```

Takes 30 minutes. Prevents the config from going stale and giving the agent
outdated instructions.

### After editing content/ — re-run the installer

If you edit files in `content/` and want those changes in your project:

```bash
cd ~/projects/my-project
~/agent-config-template/install.sh --tool claude-code
```

The installer backs up `.claude/agents/` before overwriting, so nothing is lost.

---

## Reference: all installer options

```bash
# Interactive (default) — shows menu of detected tools
./install.sh

# Specific tool, no menu
./install.sh --tool claude-code
./install.sh --tool antigravity

# Custom content directory (e.g. a filled example)
./install.sh --source examples/eargrade --tool claude-code

# See what tools are detected on this machine
./install.sh --list

# Help
./install.sh --help
```

---

## File layout quick reference

```
agent-config-template/
  install.sh                ← run this from your project root

  content/                  ← fill these in for your project
    role.md                 ← philosophy, rules, success criteria
    instructions.md         ← general dev rules
    architecture.md         ← system boundaries and constraints
    skills.md               ← when X → do Y patterns
    agent-DOMAIN.md       ← domain-specific agent (one per domain)
    workflows/
      feature-workflow.md   ← step-by-step workflow by task type
    context/
      reference.md          ← API contracts, schema, commands

  examples/
    eargrade/               ← fully filled example — use as reference

  docs/
    usage.md                ← this file
    philosophy.md           ← why each decision was made
    audit-checklist.md      ← 9-point checklist for evaluating a config
    anti-patterns.md        ← what goes wrong without this setup

  adapters/
    claude-code/convert.sh  ← called by install.sh
    antigravity/convert.sh  ← called by install.sh
```
