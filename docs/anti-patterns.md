# Anti-Patterns: What Goes Wrong Without This Setup

Each anti-pattern here was observed in a real project (Eargrade, March 2026).
Every entry follows the same structure: what it looks like, why it happens,
what the consequence is, and what the fix is.

The consequence is the important part. Anti-patterns are tempting because
they're faster in the short term. This document makes the long-term cost visible.

---

## 1. Duplicating rules across files

**What it looks like:**

`CLAUDE.md` contains a list of critical rules. `role.md` contains the same list,
slightly paraphrased. `architecture.md` restates the thin-client boundary that's
already in `role.md`.

**Why it happens:**

When you add a rule, you want it to be seen. So you put it in the most visible
file. Then, for safety, you also put it in the domain file. The duplication
feels like emphasis. It isn't.

**The consequence:**

Both copies start diverging immediately. You update one during a tech migration
(ElevenLabs → DeepInfra), forget the other. Now the agent has two instructions
in active context: "use DeepInfra for synthesis" from `architecture.md` and
"experience with ElevenLabs TTS" from `role.md`. The agent doesn't know which
to follow. It follows both — trying to reconcile them, hedging, or picking
whichever was read last. The contradictions are silent and hard to debug.

In the Eargrade audit: `CLAUDE.md` was 230 lines duplicating content from four
other files. ElevenLabs had been removed from the project; it remained in `role.md`
for an unknown number of sessions after the migration.

**The fix:**

Every fact in exactly one file. `CLAUDE.md` becomes a thin index: project
description, key commands, and `@`-imports pointing to the files that own
each fact. If you catch yourself writing the same sentence in two places,
delete one.

---

## 2. Role definition as a technology résumé

**What it looks like:**

```markdown
# Role: Senior Full-stack Engineer (Language Tech Specialist)

- React Native Expert: Deep knowledge of the RN rendering pipeline...
- AI Integration Architect: Experience with ElevenLabs (TTS)...
- Supabase Specialist: Advanced Postgres, RLS, Edge Functions...
```

**Why it happens:**

The intent is to establish credibility — to tell the agent "you know this stuff."
A list of technologies looks like a complete role definition.

**The consequence:**

The agent knows the stack but has no principles for using it. When two valid
approaches conflict — write to Supabase directly, or go through the store? —
it has nothing to resolve the conflict with. It makes a judgment call. The
judgment is inconsistent across sessions, because it's improvised each time.

More concretely: an agent with a résumé role will skip the build step when
it looks like nothing changed, write Supabase queries directly in components
when it's "just a quick fetch," and introduce native packages with `pnpm add`
when `npx expo install` isn't mentioned for this particular package.
None of these are failures of knowledge. They're failures of judgment —
the agent knows the tools but doesn't know how to decide.

**The fix:**

`role.md` answers "how does this agent think?" not "what does this agent know?"
Required sections: Philosophy (principles for trade-offs), Process (ordered steps
for each task type), Critical Rules (with "why" explanations), Success Criteria
(runnable commands), Communication Style (what to say while working).
See `content/role.md`.

---

## 3. Skills as library lists

**What it looks like:**

```markdown
## AI & Data
- TTS: ElevenLabs API (premium voiceovers).
- Alignment: Groq Whisper (word-level timestamps).
- LLM: Gemini 2.5 Flash Lite (story generation and CEFR adaptation).
```

**Why it happens:**

Skills files often start as "what does this project use?" The technology
inventory feels useful — it's fast to write and easy to read.

**The consequence:**

The agent reads "we use Gemini 2.5 Flash Lite" and knows which SDK to import.
It doesn't know:
- That Gemini must receive `responseMimeType: "application/json"` for structured output,
  or it wraps the response in markdown fences that break `JSON.parse`.
- That paragraph indices from Gemini must be normalised with `p.index ?? i`
  because Gemini sometimes omits them.
- That the DeepInfra audio response includes a `data:audio/mp3;base64,` prefix
  that must be stripped before decoding.

These aren't edge cases. They're the actual implementation details that determine
whether the code works. The agent has the library name but not the knowledge.
It guesses. The guesses are usually almost-correct — they compile, they look
right in review, they fail at runtime.

**The fix:**

Each skill entry: trigger condition + correct implementation + code example +
anti-pattern. The format is "when X → do Y":

```markdown
## When calling Gemini for structured output

Trigger: any pipeline step that expects JSON from Gemini

Always include in the request config:
  responseMimeType: "application/json"

Without it, Gemini wraps the response in ```json fences.
JSON.parse throws. The error appears at runtime, not build time.
```

---

## 4. Duplicate frontmatter

**What it looks like:**

```markdown
---
trigger: always_on
---

---

## trigger: always_on

# Actual File Title
```

**Why it happens:**

Usually a copy-paste artifact. The frontmatter block is correct, then someone
adds a section header that mirrors it, or pastes in a separator that creates
a second `---` block. It looks harmless.

**The consequence:**

The text `trigger: always_on` appears as a heading in the file body. The agent
reads it as a content instruction rather than metadata. In context, this can
override or confuse the actual frontmatter, and the file's intended trigger
behaviour becomes unpredictable. The effect is subtle — the file still loads,
it just loads with corrupted instructions.

**The fix:**

One frontmatter block, at the top. Run:

```bash
grep -n "trigger:" .agents/rules/*.md
```

Any match below line 5 is a content leak. Delete those lines.

---

## 5. One monolithic always-on agent

**What it looks like:**

A single `role.md` with `trigger: always_on` that covers all project domains:
pipeline rules, mobile rules, database rules, API integration rules — everything
in one file, always active.

**Why it happens:**

It's simpler to maintain one file. You don't have to think about which rules
apply where. Everything is always present.

**The consequence:**

Two costs that compound over time.

First, **irrelevant context on every task.** When the agent works on a UI
component, it's carrying all pipeline concurrency rules, database migration
sequences, and DeepInfra API details. These take up context tokens and
introduce noise. The signal-to-noise ratio drops with every rule you add.

Second, **diluted attention.** An agent holding 40 rules treats each as one
of forty. An agent holding 8 rules for the current domain treats each seriously.
Pipeline-specific gotchas get applied to mobile tasks. Mobile-specific
patterns contaminate pipeline code. The agent isn't wrong — it's applying
the right rules to the wrong context.

In the Eargrade audit: `role.md` carried both pipeline and mobile context
for all tasks, including audio synchronization rules during database migrations
and carplay constraints during Gemini API work.

**The fix:**

Split by domain. `role.md` (always_on) holds only universal principles:
philosophy, critical rules, communication style. `agent-[domain].md` uses
glob triggers to activate only when editing files in that domain:

```yaml
---
trigger: glob
globs: packages/pipeline/**
---
```

One file per major domain. See `content/agent-[domain].md`.

---

## 6. No success criteria

**What it looks like:**

No file in the config defines what "done" looks like. The word "done" doesn't
appear, or appears in a form like "the feature is complete and working."

**Why it happens:**

Success criteria feel obvious while you're writing the config. Of course the
agent will run the build. Of course it will test the feature. These are
self-evident. They don't need to be written down.

**The consequence:**

They need to be written down.

Without explicit criteria, the agent decides when done is done. The decision
is implicit and varies by session. Sometimes it runs the build. Sometimes it
stops when the code looks correct. Sometimes it marks a DB change complete
without verifying the migration ran, the RPC was updated, and the types reflect
the new schema.

The failures are hard to catch because the code is often mostly correct.
The build might pass. The feature might work in the happy path. The edge cases,
the theme variants, the offline state, the error handling — these get skipped
because "done" wasn't defined precisely enough to include them.

**The fix:**

Add "Done when" blocks to `role.md` (universal criteria, always visible) and
to each workflow task type (domain-specific criteria). Every criterion is either
a runnable command with expected output, or a specific observable state:

```markdown
Done when:
- `pnpm -r build` exits with zero errors
- Feature renders correctly in light + dark theme
- Data survives app restart (persistObservable confirmed)
- No Supabase queries in component files
```

---

## 7. Storing non-skills in skills/

**What it looks like:**

`skills/research.md` — 3000 words of market research: competitor analysis,
user personas, Krashen's input hypothesis, app store positioning.

**Why it happens:**

The file is important reference material. `skills/` is where reference material
goes. It goes in `skills/` because that's where things the agent should know live.

**The consequence:**

The agent scans `skills/` expecting executable patterns. It finds market research.
Two failure modes:

1. **Confusion.** The agent tries to apply the research as if it were a skill.
   Krashen's hypothesis gets invoked as a justification for implementation decisions
   that have nothing to do with language acquisition theory.
2. **Wasted context.** The agent loads 3000 words of competitor data on every task
   that touches the skills directory. Tokens used for content that will never
   be applied.

**The fix:**

`skills/` contains only "when X → do Y" patterns with code. Everything else
goes in `context/`. Background knowledge (`context/research.md`). API contracts
and schema (`context/reference.md`). The distinction is: can the agent apply
this directly to a coding task? If not, it's context, not a skill.

---

## 8. Not running skill-workshop

**What it looks like:**

The project has had 15+ sessions. `skills.md` was written at project start and
hasn't been updated since. The agent has fixed the same bug three times in
different sessions.

**Why it happens:**

skill-workshop requires setup. There's always something more urgent than
mining session history for patterns. The value is invisible until you look
for it.

**The consequence:**

Repeated mistakes stay undocumented. Each fix costs context, time, and
interrupts flow. None of the fixes accumulates into institutional knowledge.
The agent is as likely to make the mistake in session 20 as it was in session 5,
because the session that contained the fix is no longer in context.

In the Eargrade audit: 12 sessions, 592 user messages, 849 assistant messages.
skill-workshop found 6 strong skill candidates. The top one — `npx expo install`
vs `pnpm add` for native packages — had appeared in 3 separate sessions with
a score of 85. It had never been written into `skills.md`.

**The fix:**

Run skill-workshop after every significant project phase. Review the candidates.
Any pattern with score 60+ and 2+ sessions belongs in `skills.md` unless you
have a specific reason to exclude it. See `docs/audit-checklist.md` Point 8
for installation and usage.

---

## Summary table

| Anti-pattern | Immediate symptom | Long-term consequence |
|---|---|---|
| Duplicating rules | Inconsistent agent behaviour | Contradictory instructions, silent errors |
| Role as résumé | Agent knows the stack | Improvised judgment, inconsistent decisions |
| Skills as library lists | Agent uses correct library | Wrong implementation details, runtime failures |
| Duplicate frontmatter | File loads | Corrupted instructions, unpredictable trigger behaviour |
| Monolithic always-on agent | Everything works | Diluted attention, wrong-domain thinking at the edges |
| No success criteria | Tasks feel complete | Build errors, theme issues, architectural violations |
| Non-skills in skills/ | Reference is accessible | Confusion and wasted context on every task |
| Skipping skill-workshop | Current session works | Same mistakes repeat indefinitely |

---

The common thread: every anti-pattern optimises for the moment it's created.
Duplication feels like safety. A monolithic agent feels like simplicity.
Skipping skill-workshop feels like prioritisation.

The cost comes later, accumulated across sessions, measured in repeated mistakes
and debugging time. This template exists to make the cost visible before you pay it.
