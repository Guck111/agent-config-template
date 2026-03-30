---
description: {{WORKFLOW_DESCRIPTION}}
---
<!--
  Replace {{WORKFLOW_DESCRIPTION}} with a one-line description of this workflow.
  Example: "Mobile Feature Development Workflow"
  Example: "Backend Service Feature Workflow"
-->

# Workflow: {{DOMAIN_NAME}} Feature

<!--
  Step-by-step workflow for adding features in this domain.
  The agent follows this order every time — no improvising sequence.

  One workflow file per major domain.
  Rename to match your domain: mobile-feature.md, pipeline-feature.md, etc.

  Format for each task type:
  1. Flow diagram (ASCII) — the happy path at a glance
  2. Step-by-step — exact order with decision points
  3. Cross-cutting patterns — things that apply across task types
  4. "Done when" — explicit verification

  Keep this file in sync with agent-DOMAIN.md Process section.
  If the order changes here, change it there too.
-->

---

## Task Types

This workflow covers three task types. Identify which one applies before starting.

| Type | When to use |
|---|---|
| **{{TASK_TYPE_1}}** | {{TASK_TYPE_1_DESCRIPTION}} |
| **{{TASK_TYPE_2}}** | {{TASK_TYPE_2_DESCRIPTION}} |
| **{{TASK_TYPE_3}}** | {{TASK_TYPE_3_DESCRIPTION}} |

<!--
  Example:
  | Type | When to use |
  |---|---|
  | **UI-only** | New screen, component, or visual change. No new data. |
  | **Data feature** | Reads new data from DB, adds new store action. |
  | **Audio feature** | Involves TrackPlayer, word alignment, or transcript sync. |
-->

---

## Type 1: {{TASK_TYPE_1}}

```
{{TASK_TYPE_1_FLOW_DIAGRAM}}
```

<!--
  ASCII flow diagram — the happy path.
  Example:
  ```
  Read existing component → Create/update component → Apply theme via Unistyles
       ↓
  Wrap in observer() if reading from store
       ↓
  Add to navigator / screen
       ↓
  Build + verify light/dark theme
  ```
-->

### Steps

1. **{{STEP_1_TITLE}}** — {{STEP_1_DESCRIPTION}}
2. **{{STEP_2_TITLE}}** — {{STEP_2_DESCRIPTION}}
3. **{{STEP_3_TITLE}}** — {{STEP_3_DESCRIPTION}}
4. **{{STEP_4_TITLE}}** — {{STEP_4_DESCRIPTION}}

### Done when

- {{TYPE_1_CRITERION_1}}
- {{TYPE_1_CRITERION_2}}
- {{TYPE_1_CRITERION_3}}

---

## Type 2: {{TASK_TYPE_2}}

```
{{TASK_TYPE_2_FLOW_DIAGRAM}}
```

### Steps

1. **{{STEP_1_TITLE}}** — {{STEP_1_DESCRIPTION}}
2. **{{STEP_2_TITLE}}** — {{STEP_2_DESCRIPTION}}
3. **{{STEP_3_TITLE}}** — {{STEP_3_DESCRIPTION}}
4. **{{STEP_4_TITLE}}** — {{STEP_4_DESCRIPTION}}
5. **{{STEP_5_TITLE}}** — {{STEP_5_DESCRIPTION}}

### Done when

- {{TYPE_2_CRITERION_1}}
- {{TYPE_2_CRITERION_2}}
- {{TYPE_2_CRITERION_3}}

---

## Type 3: {{TASK_TYPE_3}}

```
{{TASK_TYPE_3_FLOW_DIAGRAM}}
```

### Steps

1. **{{STEP_1_TITLE}}** — {{STEP_1_DESCRIPTION}}
2. **{{STEP_2_TITLE}}** — {{STEP_2_DESCRIPTION}}
3. **{{STEP_3_TITLE}}** — {{STEP_3_DESCRIPTION}}

### Done when

- {{TYPE_3_CRITERION_1}}
- {{TYPE_3_CRITERION_2}}

---

## Cross-Cutting Patterns

<!--
  Patterns that apply across all task types in this domain.
  Not repeated per task type — stated once here.
-->

### {{CROSS_PATTERN_1_TITLE}}
<!-- Example: "Adding a new dependency" -->

{{CROSS_PATTERN_1_DESCRIPTION}}

```bash
{{CROSS_PATTERN_1_COMMAND}}
```

### {{CROSS_PATTERN_2_TITLE}}
<!-- Example: "Connecting a new database table" -->

{{CROSS_PATTERN_2_DESCRIPTION}}

```{{LANGUAGE}}
{{CROSS_PATTERN_2_CODE}}
```
