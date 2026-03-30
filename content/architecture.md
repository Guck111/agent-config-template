---
trigger: always_on
---

# Architecture: {{ARCHITECTURE_PATTERN_NAME}}

<!--
  The architectural boundaries and constraints the agent must never cross.
  Focus on decisions that are non-obvious and that have been violated before
  (or would be violated without this file).

  Not a general description of the system — a set of constraints.
  The agent reads this as "here is what I must not do and why."
-->

## Core Principle

{{CORE_ARCHITECTURAL_PRINCIPLE}}
<!--
  One or two sentences. The fundamental split that everything else follows from.
  Example: "The mobile application is a Thin Client. It must NEVER contain logic
  for content generation, voice synthesis, or text alignment. Its sole purpose
  is to fetch, store (offline-first), and render data provided by the backend."
-->

## Division of Concerns

<!--
  For each major system component: what it owns, what it must never do.
  2–4 components is typical. More than 4 suggests the architecture needs clarity, not documentation.
-->

### {{COMPONENT_1_NAME}}

**Owns:**
- {{COMPONENT_1_RESPONSIBILITY_1}}
- {{COMPONENT_1_RESPONSIBILITY_2}}
- {{COMPONENT_1_RESPONSIBILITY_3}}

**Must never:**
- {{COMPONENT_1_FORBIDDEN_1}}
- {{COMPONENT_1_FORBIDDEN_2}}

<!--
  Example component:
  ### Content Pipeline (packages/pipeline)
  **Owns:**
  - Content generation and CEFR adaptation
  - Voice synthesis and word-level alignment
  - Atomic persistence to the database

  **Must never:**
  - Run inside the mobile app
  - Be triggered by a user interaction directly
-->

### {{COMPONENT_2_NAME}}

**Owns:**
- {{COMPONENT_2_RESPONSIBILITY_1}}
- {{COMPONENT_2_RESPONSIBILITY_2}}

**Must never:**
- {{COMPONENT_2_FORBIDDEN_1}}
- {{COMPONENT_2_FORBIDDEN_2}}

## Data Flow

<!--
  How data moves through the system. Direction matters.
  Draw the arrows. State which direction is forbidden.

  Example:
  Pipeline → Supabase → Mobile app
  Data flows one way. Mobile never writes content. Pipeline never reads UI state.
-->

```
{{DATA_FLOW_DIAGRAM}}
```

<!--
  Example:
  ```
  [Pipeline] → generates → [Supabase DB]
  [Mobile App] ← fetches ← [Supabase DB]
  [Mobile App] → writes → [Legend-State] → syncs → [Supabase DB]
  ```
-->

## {{PERSISTENCE_OR_DATA_SECTION_NAME}}

<!--
  The persistence model, if it has architectural constraints.
  Example: atomic writes, offline-first requirements, RPC patterns.
-->

{{PERSISTENCE_RULES}}

<!--
  Example:
  All inserts go through a single Postgres function:
    insert_article_with_variants(p_article JSONB, p_variants JSONB) RETURNS UUID

  If any step fails before this call, nothing is written to the database.
  If the RPC itself fails, Postgres rolls back the entire transaction.
  No orphaned rows.
-->

## Restrictions for AI Agent

> [!CAUTION]
>
> - **DO NOT** {{AGENT_RESTRICTION_1}}
> - **DO NOT** {{AGENT_RESTRICTION_2}}
> - **DO NOT** {{AGENT_RESTRICTION_3}}

<!--
  Restate the most critical architectural constraints as explicit prohibitions.
  These should be the things an agent would most plausibly do wrong.

  Example:
  - DO NOT install AI-related SDKs in the mobile app.
  - DO NOT write content generation logic in the mobile app.
  - DO NOT call persistArticle and persistVariant separately — use persistArticleWithVariants.
-->
