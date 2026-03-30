# Audit Checklist: 9 Points for Evaluating an Agent Config

Run this checklist on any existing agent configuration before migrating to this template.
Each point has a pass condition, a failure signal, and the fix.

Estimated time: 30–45 minutes for a config of typical size.
When to run: after major tech changes, after significant project phases, when the agent
starts repeating mistakes.

---

## How to use this checklist

Open your agent config directory alongside this document.
Go through each point in order — they're roughly ordered by how fast
you can identify the problem.

Mark each item:
- `✅ pass` — clear
- `⚠️ partial` — present but incomplete
- `❌ fail` — missing or wrong

Any `❌` is a fix before the next session. Any `⚠️` is a fix before the next project phase.

---

## Point 1 — Single source of truth

**Question:** Does any fact appear in more than one file?

**How to check:**
- Pick 3 facts from your config: a critical rule, a technology name, an API endpoint.
- `grep` for each across all config files.
- If it appears more than once, it's duplicated.

```bash
# Example: check if "supabase" appears in more than one rules file
grep -rl "supabase" .agents/rules/
```

**Failure signals:**
- `CLAUDE.md` contains rules that also exist in `architecture.md` or `role.md`
- Tech stack listed in both `role.md` and `skills.md`
- API endpoint or env var name appears in 2+ files

**What goes wrong:** When you update one copy, the other stays stale.
The agent gets contradictory instructions and follows whichever it read last.

**Fix:** Every fact in exactly one file. `CLAUDE.md` is a thin index of `@`-imports only.
Move unique content to `context/reference.md`. Delete the duplicates.

---

## Point 2 — role.md describes behaviour, not technology

**Question:** If you remove all technology names from `role.md`, is anything left?

**How to check:**
Read `role.md`. Look for these sections:
- [ ] Philosophy — principles that resolve trade-offs
- [ ] Process — ordered steps for each task type
- [ ] Critical Rules — with "why" explanations, not just "what"
- [ ] Success Criteria — runnable commands, not vague descriptions
- [ ] Communication Style — what the agent says while working

**Failure signals:**
- `role.md` is a list of technologies and expertise levels
- No mention of what "done" looks like
- Rules have no explanations
- The agent's personality is "Senior Full-stack Engineer with deep knowledge of X"

**What goes wrong:** The agent knows the stack but not how to think.
It makes the same judgment errors session after session because it has
tools but no principles for using them.

**Fix:** Rewrite `role.md` using the template in `content/role.md`.
Each critical rule gets a one-sentence "why." Process gets explicit steps.
Success criteria become runnable commands.

---

## Point 3 — Skills describe "when X → do Y", not library lists

**Question:** Does each skill entry tell the agent exactly what code to write?

**How to check:**
Open `skills.md`. For each entry, ask:
- Does it have a trigger condition ("when X")?
- Does it have a concrete implementation ("do Y")?
- Does it have a code example?
- Does it have an anti-pattern (what not to do)?

**Failure signals:**
```markdown
❌  ## AI & Data
    - TTS: ElevenLabs API
    - LLM: Gemini 2.5 Flash Lite

✅  ## When calling Gemini for structured output
    Trigger: any step that calls the Gemini API expecting JSON
    Always set responseMimeType: "application/json" in the request config.
    Without it, Gemini wraps the JSON in markdown fences — JSON.parse throws.
```

**What goes wrong:** The agent reads "we use X" but doesn't know how.
It guesses. The guesses are usually almost-correct — they pass code review
and fail in production.

**Fix:** Rewrite each skill entry as a trigger + implementation + code example.
Use the `content/skills.md` template. Prioritise skills that have caused
repeated mistakes — run skill-workshop to find them (see Point 8).

---

## Point 4 — Frontmatter is clean

**Question:** Does the `trigger:` metadata appear only in frontmatter, not in file content?

**How to check:**
```bash
grep -n "trigger:" .agents/rules/*.md
```

Look at the line numbers. Frontmatter `trigger:` should be in lines 1–5.
Anything below line 10 is a content leak.

**Failure signals:**
```markdown
---
trigger: always_on    ← correct: frontmatter
---

---                   ← wrong: extra separator

## trigger: always_on ← wrong: metadata as content heading

# Actual File Title
```

**What goes wrong:** The text `trigger: always_on` becomes a heading
the agent reads as an instruction. Depending on placement, it can override
or confuse the actual frontmatter metadata.

**Fix:** Delete any lines after the closing `---` that repeat frontmatter keys.
One frontmatter block, at the top, nothing repeated below.

---

## Point 5 — There is a workflow file for each major development domain

**Question:** For every major task type in the project, is there a workflow
that tells the agent what order to do things in?

**How to check:**
List your 2–3 most common task types (e.g. "add a UI feature", "extend the pipeline",
"add a DB field"). Check whether there is a workflow file that covers each.

**Failure signals:**
- Only one workflow file exists for a project with 2+ distinct domains
- Workflow file exists but has no "Done when" section
- The agent has to guess the correct sequence for common tasks

**What goes wrong:** Without a workflow, the agent invents its own order.
It might write the component before the migration, or update types before the
schema exists. Each session, it invents a different order.

**Fix:** Create a workflow file for each domain using `content/workflows/feature-workflow.md`
as the template. Each workflow needs: task types, step-by-step sequence, and explicit
"Done when" verification for each type.

---

## Point 6 — Success criteria are explicit

**Question:** Does the agent know, without asking, when a task is complete?

**How to check:**
Find every place the word "done" or "complete" appears in your config.
Check if it's followed by runnable commands or by vague descriptions.

**Failure signals:**
```markdown
❌  Done when the feature works correctly.

✅  Done when:
    - `pnpm -r build` exits with zero errors
    - Feature renders in light + dark theme on simulator
    - No console errors during interaction
    - Supabase queries only in store actions, not in components
```

**What goes wrong:** Without explicit done criteria, the agent marks tasks
complete when the code looks finished, not when it's verified to work.
Build errors, theme issues, and architectural violations slip through.

**Fix:** Add "Done when" blocks to `role.md` (always visible) and to each
workflow task type. Every criterion must be a runnable command or a
specific observable state.

---

## Point 7 — context/ is separated from skills/

**Question:** Does `skills/` (or its equivalent) contain only executable patterns?

**How to check:**
Read every file in your skills directory. For each file, ask:
"Can the agent apply this directly to a coding task?"
If the answer is "no, this is background information," it's in the wrong place.

**Failure signals:**
- Market research in `skills/`
- Competitor analysis in `skills/`
- User persona documents in `skills/`
- Architecture decisions written as prose essays in `skills/`

**What goes wrong:** The agent scans `skills/` expecting executable patterns.
It finds a 3000-word market analysis. It either tries to apply it as a pattern
(confusion) or ignores it (wasted context tokens).

**Fix:** Create `context/` for background knowledge. Move anything that isn't
a "when X → do Y" pattern. `context/reference.md` for API contracts and schema.
`context/research.md` for market and product research.

---

## Point 8 — skill-workshop has been run on accumulated sessions

**Question:** Have repeated agent mistakes from real sessions been documented as skills?

**How to check:**
- Count your sessions since the last skill-workshop run.
- If it's more than ~10 sessions, you have uncaptured patterns.
- Think of 2–3 mistakes the agent made more than once. Are they in `skills.md`?

**How to run skill-workshop:**
```bash
# Install
git clone https://github.com/grayodesa/skill-workshop ~/.skill-workshop

# Copy agents to your Claude Code setup
cp ~/.skill-workshop/agents/* ~/.claude/agents/
cp -r ~/.skill-workshop/skills/* ~/.claude/skills/

# Run in Claude Code (in your project directory)
/skill-workshop
# or target a specific project
/skill-workshop /path/to/project
```

**What it finds:** Patterns with a score and session count.
Score 60+ with 2+ sessions = strong skill candidate.
Review the candidates, approve the ones that match real recurring problems.

**What goes wrong without it:** Repeated mistakes stay undocumented.
The agent fixes the same bug in session 3, session 7, and session 12.
Each fix costs context and time. None of them survives to the next session.

**Fix:** Run skill-workshop, review candidates, add approved patterns to `skills.md`
using the "when X → do Y" format.

---

## Point 9 — Specialised agents use glob triggers, not always-on

**Question:** Is the agent carrying context that's irrelevant to the current task?

**How to check:**
Count how many rules in your always-on files are domain-specific
(apply only to pipeline tasks, or only to mobile tasks, but not both).
If more than 30% of always-on content is domain-specific, specialisation is overdue.

**Failure signals:**
- One `role.md` with `trigger: always_on` that contains pipeline-specific rules
  AND mobile-specific rules AND database-specific rules
- Agent mentions pipeline gotchas when working on a UI component
- Agent mentions mobile patterns when writing a migration

**What goes wrong:** Irrelevant context on every task. More tokens, more noise,
higher hallucination risk. Domain-specific rules diluted by volume — an agent
holding 40 rules treats each as one of forty.

**Fix:** Split into:
- `role.md` (always_on) — universal principles only: philosophy, critical rules, communication style
- `agent-[domain].md` (glob: `path/to/domain/**`) — domain identity, process, patterns, success criteria

Use the `content/agent-[domain].md` template. One file per major domain.

---

## Scoring

| Points passed | Status |
|---|---|
| 9 / 9 | ✅ Config is solid. Schedule next audit after next major tech change. |
| 7–8 / 9 | ⚠️ Minor gaps. Fix ❌ items before next project phase. |
| 5–6 / 9 | ⚠️ Meaningful gaps. Agent is making correctable mistakes every session. |
| < 5 / 9 | ❌ Config needs rebuilding. Use this template from scratch. |

---

## After the audit

1. Fix all `❌` items. Use the relevant template files in `content/`.
2. Document what you changed and why — the audit itself is institutional memory.
3. Schedule the next audit. Triggers: new technology introduced, architecture change,
   agent starts making the same mistake twice.
