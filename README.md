# agent-config-template

A structured template for configuring AI coding agents on real projects.
Born from auditing and rebuilding the agent setup for [Eargrade](https://github.com/guck111/audio-english) —
an AI-first mobile language learning app.

## The problem this solves

Most agent configs are either:
- A list of technologies ("we use React, Supabase, TypeScript")
- A list of rules ("always use TypeScript", "never use var")

Neither tells the agent *how to think*, *what order to do things in*,
or *why the rules exist*. The result: the agent knows your stack
but still makes the same mistakes session after session.

## What's different here

**Rules have reasons.** "Never use `pnpm add` for native packages" is useless
without "...because it pulls react-native@0.79 instead of 0.76 and breaks
the native build silently." An agent that understands *why* won't look
for exceptions.

**One source of truth.** If a fact lives in two files, one is already wrong.
Schema in migrations. Types in one place. No restating in CLAUDE.md
what's already in architecture.md.

**Specialised agents, not one generic one.** A pipeline engineer and a mobile
engineer have different checklists, different gotchas, different done criteria.
Glob triggers activate the right agent for the right files.

**Skills over rules.** Rules say what not to do. Skills say exactly what to do:
"When X → do Y, here's the code."

**Done criteria.** Every workflow ends with explicit verification steps —
not "looks good" but "run this command and check this output."

## Structure
```
content/                   ← tool-agnostic source of truth
  role.md                  ← Identity, Philosophy, Critical Rules, Communication Style
  instructions.md          ← general dev rules
  architecture.md          ← architectural boundaries and constraints
  skills.md                ← when X → do Y patterns
  agent-[domain].md        ← specialised agent template (one per domain)
  workflows/
    feature-workflow.md    ← step-by-step workflow by task type
  context/
    reference.md           ← API contracts, types, schema quick reference

adapters/                  ← converts content/ into tool-specific formats
  claude-code/
    convert.sh             ← writes to .claude/agents/ and .claude/skills/
  antigravity/
    convert.sh             ← writes SKILL.md files for ~/.gemini/antigravity/

examples/
  eargrade/                ← fully filled template from a real project
    ...

docs/
  philosophy.md            ← why each decision was made
  audit-checklist.md       ← 9-point checklist for auditing existing configs
  anti-patterns.md         ← what goes wrong without this setup and why

install.sh                 ← interactive installer (detects installed tools)
```

## Quick start
```bash
git clone https://github.com/guck111/agent-config-template.git
cd agent-config-template

# Interactive install — detects Claude Code and Antigravity automatically
./install.sh

# Or target a specific tool
./install.sh --tool claude-code
./install.sh --tool antigravity
```

Then fill in the placeholders in `content/` for your project.
See `examples/eargrade/` for a complete real-world example.

## Supported tools

| Tool | Status |
|---|---|
| Claude Code | ✅ v1 |
| Antigravity (Gemini) | ✅ v1 |
| Cursor | 🔜 planned |
| Windsurf | 🔜 planned |

## The audit checklist

Before building this template we audited an existing agent config and found 9 issues.
The checklist is in [`docs/audit-checklist.md`](docs/audit-checklist.md) —
use it to evaluate your current setup before migrating.

## Inspired by

- [agency-agents](https://github.com/msitarzewski/agency-agents) — agent personality patterns
- [skill-workshop](https://github.com/grayodesa/skill-workshop) — mining session history for skills

## License

MIT
