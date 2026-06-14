# AGENTS.md

Instructions for an AI agent asked to set up an agent config for a project using
this template. If a human says something like *"read this repo and set up an
agent config for my project,"* this file is the procedure. Follow it.

## What this repo is

A tool-agnostic template for writing agent configs that actually change agent
behaviour. The core idea: every rule carries the reason it exists, every fact
lives in one place, agents are split by domain, and "done" is a runnable command
— not a feeling. `content/` is the source of truth; the `adapters/` convert it
into Claude Code or Antigravity formats.

## Procedure

1. **Read `content/`** — the tool-agnostic source of truth: `role.md` (identity,
   philosophy, critical rules, communication style), `instructions.md`,
   `architecture.md`, `skills.md` (when X → do Y), `agent-DOMAIN.md` (one per
   domain, glob-triggered), `workflows/feature-workflow.md`, `context/reference.md`.
   The `{{PLACEHOLDERS}}` are what you fill in.

2. **Read `examples/eargrade/`** — the same structure filled in from a real
   project. `examples/eargrade/CLAUDE.md` is the reference for what a finished,
   self-contained config looks like. Match its shape, not its content.

3. **Ask the user before generating.** Don't guess the project. Get: stack and
   languages; repo layout (monorepo or not, which packages/apps); the 2–3
   architectural boundaries that matter and what each side may and may not do;
   known gotchas (the bugs that actually bit them); build and test commands; what
   "done" means, as commands. If you can't name the failure mode behind a rule,
   you don't have enough to write it — ask.

4. **Generate the config**, filling placeholders with real project data.
   - **Where the files go (Claude Code):** the layout
     `adapters/claude-code/convert.sh` installs — `.claude/agents/` for `role.md`,
     `instructions.md`, `architecture.md`, `skills.md`, each `agent-<domain>.md`,
     and a `workflows/` subdir; `.claude/context/` for `reference.md`; plus a root
     `CLAUDE.md` that `@`-imports them all (see `content/CLAUDE.md` for the index
     shape). The script copies files verbatim — it adds no frontmatter and renames
     nothing, so the content quality is entirely on you.
   - **How to author each file — imitate `examples/eargrade/`, not the script:**
     give each domain its own `agent-<domain>.md` with a glob trigger
     (`trigger: glob` + `globs: <path>/**`, as in `examples/eargrade/agent-mobile.md`)
     and its own `workflows/<domain>-feature.md` (e.g. `mobile-feature.md`). The
     template ships one generic `agent-DOMAIN.md` and `feature-workflow.md` — split
     and rename them per domain.
   - **Antigravity:** one `SKILL.md` per content file, laid out as
     `adapters/antigravity/convert.sh` does it.

5. **Write every rule with its reason.** This is the whole point of the template.
   `NEVER do X` alone is a soft preference the agent talks itself out of.
   `NEVER do X — because Y broke this way` is something it can reason from. No
   reason, no rule.

## Do not

- **Don't copy Eargrade's specifics** (thin client, Supabase RPC, Gemini,
  DeepInfra, Legend-State, CEFR levels…) into another project. It's a shape to
  imitate, not content to paste.
- **Don't duplicate facts across files.** One source of truth. Point at the real
  file (types, migrations) instead of restating it — copies go stale.
- **Don't run `install.sh`.** It's an interactive installer for a human at a
  terminal. You assemble the files directly.
- **Don't invent rules you can't justify.** A rule without a concrete failure
  mode is noise.

## Done when

The generated config has no `{{PLACEHOLDER}}` left (verify with
`./validate.sh --dir <output-dir>`), every critical rule states its failure mode,
each domain agent has a glob trigger, and the "done" criteria are commands the
user can run. `examples/eargrade/CLAUDE.md` is your visual target for the result.
