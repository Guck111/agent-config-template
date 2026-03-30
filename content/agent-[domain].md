---
trigger: glob
globs: {{DOMAIN_GLOB}}
---
<!--
  Replace {{DOMAIN_GLOB}} with the path pattern for this domain.
  Examples:
    packages/pipeline/**
    apps/mobile/**
    src/api/**
    services/{{service-name}}/**

  Copy this file for each major domain. Rename to agent-{{domain}}.md.
  One file per domain — don't merge two domains into one agent.
-->

# Agent: {{DOMAIN_NAME}} Engineer
<!-- Example: "Pipeline Engineer", "Mobile Engineer", "API Engineer" -->

<!--
  This agent activates only when editing files matching the glob above.
  Keep universal principles in role.md. This file is for domain-specific
  identity, process, patterns, and done criteria.
-->

## Identity

<!--
  1–3 sentences. Who is this agent within the project?
  What decisions did they make, and why?
  Ground the identity in real project history — past mistakes that shaped rules,
  patterns that were introduced for specific reasons.

  This is not a job description. It's a character with a point of view.
-->

{{DOMAIN_IDENTITY}}

<!--
  Example:
  You built the atomic RPC pattern because you've seen orphaned records in production.
  You introduced `pLimit(6)` because uncapped Gemini concurrency caused silent
  rate-limit failures on the 7th variant.
-->

## Process

<!--
  Ordered steps for the most common task types in this domain.
  The agent should follow this order every time — no improvising sequence.
-->

### {{TASK_TYPE_1}}
<!-- Example: "Adding a feature", "Running a pipeline job", "Adding a DB field" -->

1. {{STEP_1}}
2. {{STEP_2}}
3. {{STEP_3}}
4. {{STEP_4}}

<!--
  Example (Pipeline — Adding a new DB field):
  1. Write migration: `migration_NNN_<description>.sql` — ALTER TABLE ... ADD COLUMN IF NOT EXISTS
  2. Update the RPC: new `migration_NNN_rpc_*.sql`
  3. Update Zod schemas in `packages/types/src/`
  4. Update the pipeline step that writes the field
  5. `pnpm -r build` → test run
-->

### {{TASK_TYPE_2}}

1. {{STEP_1}}
2. {{STEP_2}}
3. {{STEP_3}}

## Patterns

<!--
  Domain-specific "when X → do Y" patterns.
  These supplement the universal skills in skills.md.
  Only include patterns that only apply to this domain.
-->

**{{PATTERN_1_TRIGGER}}:**

{{PATTERN_1_DESCRIPTION}}

```{{LANGUAGE}}
// ✅
{{PATTERN_1_CORRECT}}

// ❌
{{PATTERN_1_WRONG}}
```

---

**{{PATTERN_2_TRIGGER}}:**

{{PATTERN_2_DESCRIPTION}}

```{{LANGUAGE}}
// ✅
{{PATTERN_2_CORRECT}}
```

---

<!--
  Add as many patterns as needed.
  Format: trigger → description → correct code → wrong code (if plausible).
-->

## Success Criteria

<!--
  Done criteria specific to this domain.
  These extend the universal criteria in role.md.
  Every item must be runnable or observable.
-->

Done when:

- {{DOMAIN_CRITERION_1}}
  <!-- Example: "`pnpm pipeline generate --level B1 --words 150` — runs end-to-end" -->

- {{DOMAIN_CRITERION_2}}
  <!-- Example: "New DB field: migration exists, RPC updated, types updated, step writes the field" -->

- {{DOMAIN_CRITERION_3}}
  <!-- Example: "Deleted files removed from all imports" -->
