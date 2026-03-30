# Reference: {{PROJECT_NAME}}

<!--
  The single source of truth for facts the agent needs to look up during a session:
  API contracts, types, schema, environment variables, file structure.

  Rules for this file:
  - Facts only. No rules, no philosophy, no process.
  - If a fact lives here, it lives NOWHERE ELSE.
  - Update this file when the project changes. Stale reference is worse than no reference.
  - This file lives in context/ — it's background knowledge, not a skill.
-->

---

## Environment Variables

<!--
  All env vars the agent might reference.
  Group by: required for build, required at runtime, optional.
  Never put actual values here — use .env.example for that.
-->

### {{SERVICE_1_NAME}}
<!-- Example: "Supabase" -->

```
{{ENV_VAR_1}}={{DESCRIPTION_1}}
{{ENV_VAR_2}}={{DESCRIPTION_2}}
```

### {{SERVICE_2_NAME}}
<!-- Example: "AI Services" -->

```
{{ENV_VAR_3}}={{DESCRIPTION_3}}
{{ENV_VAR_4}}={{DESCRIPTION_4}}
```

<!--
  Example:
  ### Supabase
  ```
  SUPABASE_URL=project URL (safe for client)
  SUPABASE_ANON_KEY=anonymous key (safe for client)
  SUPABASE_SERVICE_ROLE_KEY=service role key (NEVER expose to client)
  ```

  ### AI Services
  ```
  GEMINI_API_KEY=Gemini API key (pipeline only)
  DEEPINFRA_API_KEY=DeepInfra API key (pipeline only)
  ```
-->

---

## Database Schema

<!--
  The tables the agent will most frequently touch.
  Not a full schema dump — just the columns that matter for agent tasks.
  Update when migrations run.
-->

### {{TABLE_1_NAME}}

```sql
{{TABLE_1_SCHEMA}}
```

<!--
  Example:
  ### articles
  ```sql
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid()
  title       TEXT NOT NULL
  source_type TEXT CHECK (source_type IN ('generated', 'url'))
  source_url  TEXT
  source_title TEXT
  created_at  TIMESTAMPTZ DEFAULT now()
  ```
-->

### {{TABLE_2_NAME}}

```sql
{{TABLE_2_SCHEMA}}
```

---

## API Contracts

<!--
  External API calls the agent needs to make correctly.
  Shape of request + shape of response + known gotchas.
-->

### {{API_1_NAME}}
<!-- Example: "Gemini — Structured Output" -->

**Request:**
```{{LANGUAGE}}
{{API_1_REQUEST_SHAPE}}
```

**Response:**
```{{LANGUAGE}}
{{API_1_RESPONSE_SHAPE}}
```

**Gotchas:**
- {{API_1_GOTCHA_1}}
- {{API_1_GOTCHA_2}}

<!--
  Example:
  ### Gemini — Structured Output

  **Request:**
  ```typescript
  {
    model: "gemini-2.5-flash-lite",
    generationConfig: {
      responseMimeType: "application/json",  // ← required, or response is wrapped in ```json
      responseSchema: { ... }
    }
  }
  ```

  **Response:**
  ```typescript
  {
    candidates: [{
      content: { parts: [{ text: string }] }
    }]
  }
  ```

  **Gotchas:**
  - `responseMimeType: "application/json"` is required. Without it, Gemini wraps JSON in markdown fences.
  - Paragraph indices may be missing: always normalise with `p.index ?? i`.
-->

---

## Types

<!--
  Shared types the agent needs to reference.
  If types live in a shared package, show where — don't redefine them here.
-->

```{{LANGUAGE}}
// Source: {{TYPES_FILE_PATH}}
{{KEY_TYPE_1}}

{{KEY_TYPE_2}}
```

<!--
  Example:
  ```typescript
  // Source: packages/types/src/story.ts

  export type CefrLevel = 'A1' | 'A2' | 'B1' | 'B2' | 'C1' | 'C2'

  export interface StoryVariant {
    id: string
    article_id: string
    cefr_level: CefrLevel
    body: string
    audio_url: string
    alignment: WordAlignment[]
  }
  ```
-->

---

## File Structure

<!--
  The parts of the repo the agent needs to navigate.
  Not a full tree — just the directories that matter for agent tasks.
-->

```
{{REPO_STRUCTURE}}
```

<!--
  Example:
  ```
  apps/mobile/
    src/
      components/    ← shared UI components
      screens/       ← screen-level components
      store/         ← Legend-State store actions
      navigation/    ← React Navigation setup

  packages/pipeline/
    src/
      steps/         ← pure step functions (one per pipeline stage)
      references/    ← CEFR reference JSON files
    supabase/        ← migration SQL files

  packages/types/
    src/
      story.ts       ← article + variant types
  ```
-->

---

## Key Commands

<!--
  Commands the agent runs most often.
  Enough context to run them correctly.
-->

```bash
# Build all packages
{{BUILD_COMMAND}}

# {{COMMAND_2_DESCRIPTION}}
{{COMMAND_2}}

# {{COMMAND_3_DESCRIPTION}}
{{COMMAND_3}}
```

<!--
  Example:
  ```bash
  # Build all packages (always run after source changes)
  pnpm -r build

  # Run pipeline in generate mode
  pnpm pipeline generate --level B1 --category travel --lang en --words 300

  # Run pipeline in import mode
  pnpm pipeline import --url https://learningenglish.voanews.com/a/...

  # Start mobile dev server
  pnpm --filter @repo/mobile start
  ```
-->
