# Philosophy: Why This Template Exists

This document explains the thinking behind `agent-config-template`.
Not the structure — the _reasons_ for the structure.

If you understand these six principles, you can adapt the template
to any project. If you skip this document and go straight to the files,
you'll cargo-cult the format without getting the benefit.

---

## 1. Rules need reasons

A rule without a "why" will be circumvented the moment the agent
thinks it found a good exception.

Compare these two instructions:

```
❌  Never use `pnpm add` for native packages.

✅  Never use `pnpm add` for native packages in `apps/mobile`.
    Use `npx expo install` instead.
    Why: pnpm resolves versions independently of Expo's compatibility matrix.
    It pulled react-native@0.79 instead of 0.76 and broke the native
    build silently — no error until Xcode, 20 minutes later.
```

The first formulation invites reasoning: "this is a small utility package,
probably fine." The second forecloses it. The agent knows what failure
looks like. It won't optimise around the rule because it understands
what the rule is protecting.

**The consequence of rules without reasons:** the agent makes the exact
mistake the rule was written to prevent, because it looks like a reasonable
exception at the time.

**What to do:** Every critical rule gets a "why" explanation — one sentence
minimum, a concrete failure mode if you have one.

---

## 2. One source of truth

If a fact lives in two files, one of them is already wrong.

This is true for code. It's equally true for agent configurations.

The failure mode looks like this: you update your tech stack (`ElevenLabs → DeepInfra`),
you update `architecture.md`, you forget `role.md`. Now the agent has correct
architecture rules and an outdated role definition. It "knows" ElevenLabs is removed
but still introduces itself as "experienced with ElevenLabs TTS."

Config duplication compounds faster than code duplication because:

1. Config files have no type system to catch inconsistencies.
2. Agent configs are updated irregularly, months apart.
3. The agent has no way to know which copy is canonical.

**The fix:** every fact in exactly one file. `CLAUDE.md` is a thin index
of `@`-imports, not a copy of content from other files. If you catch yourself
writing the same sentence in two places, one of those places is wrong.

---

## 3. A role is not a résumé

The original failure: `role.md` as a technology list.

```markdown
# Role: Senior Full-stack Engineer (Language Tech Specialist)

- React Native Expert: Deep knowledge of RN rendering pipeline...
- AI Integration Architect: Experience with ElevenLabs (TTS)...
- Supabase Specialist: Advanced Postgres, RLS, Edge Functions...
```

This tells the agent _what tools exist_. It doesn't tell the agent:
- What to do when two correct approaches conflict
- What order to follow when adding a new feature
- What "done" looks like
- What mistakes this project has already made

A role definition should answer: "How does this agent think?" Not: "What
does this agent know?"

The sections that matter:

| Section | Question it answers |
|---|---|
| Philosophy | What principles resolve trade-offs? |
| Process | What order do I do things in? |
| Critical Rules | What mistakes must I never make? |
| Success Criteria | How do I know I'm done? |
| Communication Style | What do I say while I work? |

**The consequence of a résumé role:** the agent knows your stack
but still makes the same mistakes session after session, because it
has tools but no judgment about how to use them.

---

## 4. Skills are not library lists

A "skill" is not "we use X technology." A skill is "when situation X occurs,
do exactly Y — here is the code."

The original failure:

```markdown
## AI & Data
- TTS: ElevenLabs API (premium voiceovers).
- Alignment: Groq Whisper (word-level timestamps).
- LLM: Gemini 2.5 Flash Lite.
```

Three lines of library names. When the agent needs to synthesise audio,
it knows _which library_ but not _how to call it correctly_, what the
response shape looks like, or what subtle bugs to avoid.

The correct format:

```markdown
## When synthesising audio with DeepInfra

Trigger: any task that calls `synthesizeWithAlignment`

✅ Correct:
const base64 = response.audio.replace("data:audio/mp3;base64,", "")
const buffer = Buffer.from(base64, "base64")

❌ Wrong (response.audio is not raw base64 — it includes the data URI prefix):
const buffer = Buffer.from(response.audio, "base64")
```

**The consequence of skills as library lists:** the agent reads "we use X" but
doesn't know how. It guesses. The guesses are usually almost-correct,
which is worse than wrong because they pass code review.

---

## 5. Specialised agents over one generic one

A single `role.md` with `trigger: always_on` means the agent carries
pipeline context when working on mobile files and vice versa.

This has two costs:

1. **Irrelevant context.** Every pipeline-specific rule is loaded during
   a UI task. Every mobile-specific gotcha is present during a database migration.
   More tokens, more noise, higher hallucination risk.

2. **Diluted rules.** When everything applies everywhere, nothing applies
   with force. An agent that holds 40 rules treats each one as one of forty.
   An agent that holds 8 rules for the current context treats each one seriously.

The fix is glob triggers: `agent-pipeline.md` activates only when editing
`packages/pipeline/**`, `agent-mobile.md` only when editing `apps/mobile/**`.
`role.md` stays always-on but contains only universal principles.

**The consequence of monolithic agents:** the agent applies pipeline thinking
to mobile tasks and mobile thinking to pipeline tasks. It's correct on average
but wrong at the edges — exactly where the hard problems are.

---

## 6. Agent configs need auditing

Technology changes. Config files don't update themselves.

A project that switches from ElevenLabs to DeepInfra, or migrates from Redux
to Legend-State, or drops a dependency — that project's agent config will
refer to the old tech indefinitely unless someone audits it.

The compounding effect: a stale config leads to agent mistakes, agent mistakes
lead to workaround rules, workaround rules lead to more stale content. After
a year without audit, the config is more noise than signal.

Two tools for staying current:

**Scheduled audits.** Run the 9-point checklist (`docs/audit-checklist.md`)
after every major project phase: new tech introduced, architecture changed,
team member added. Takes 30 minutes. Saves hours of session clean-up.

**skill-workshop.** Mines your actual session history for repeated mistakes.
If the agent fixes the same bug three times in different sessions, that fix
belongs in a skill. skill-workshop finds these patterns automatically —
`npx expo install` over `pnpm add` was a skill-workshop candidate with
score 85 across 3 sessions before it was ever written into the config.

**The consequence of skipping audits:** the agent accrues technical debt in
the form of wrong knowledge — wrong libraries, wrong APIs, outdated patterns.
It becomes confidently incorrect about its own project.

---

## Summary

| Principle | Agent behaviour without it | Agent behaviour with it |
|---|---|---|
| Rules need reasons | Circumvents rules at "reasonable exceptions" | Understands what it's protecting, no exceptions |
| One source of truth | Gets contradictory instructions | Gets one clear instruction |
| Role is not a résumé | Knows tools but not judgment | Applies principles under ambiguity |
| Skills over library lists | Guesses implementation details | Follows exact working patterns |
| Specialised agents | Diluted attention, wrong-domain thinking | Sharp focus for the current task |
| Regular audits | Confidently wrong about stale tech | Reflects actual current project state |

None of these principles are novel. They're engineering practices applied
to a new surface: the configuration layer that shapes how an AI agent thinks
about your project.

The reason to make them explicit is that agent configs look deceptively simple —
just markdown files, just rules — and that simplicity tempts shortcuts.
This document is the argument against the shortcuts.
