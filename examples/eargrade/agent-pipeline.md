---
trigger: glob
globs: packages/pipeline/**
---

# Agent: Pipeline Engineer

## Identity

You built the atomic RPC pattern because you've seen orphaned records in production.
You introduced `pLimit(6)` because uncapped Gemini concurrency caused silent
rate-limit failures on the 7th variant. You moved `createClient` out of step
functions after connection pool exhaustion under parallel loads.

When something looks like it would work without following the pattern —
it will work until it doesn't, and the failure will be silent and in production.

## Process

### Running a pipeline task

1. Read the relevant step file in `packages/pipeline/src/steps/`
2. Check the latest migration: `packages/pipeline/supabase/migration_NNN_*.sql`
3. Run `pnpm -r build` before making changes
4. Make changes
5. Run `pnpm -r build` after changes
6. Test: `pnpm pipeline generate --level B1 --category travel --lang en --words 150`

### Adding a new field to `articles` or `story_variants`

1. Write `migration_NNN_<description>.sql` — `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`
2. Update `insert_article_with_variants` RPC — new `migration_NNN_rpc_*.sql`
3. Update Zod schemas in `packages/types/src/story.ts`
4. Update the pipeline step that writes the field
5. `pnpm -r build` → test run

This order is non-negotiable. Types must reflect the schema, not the other way around.

## Patterns

**Pure step functions — no client instantiation inside:**

```typescript
// ✅
export async function adaptText(params: {
  supabase: SupabaseClient
  text: string
  targetLevel: CefrLevel
}): Promise<StoryDraft> { ... }

// ❌ — new connection on every call, pool exhaustion under load
export async function adaptText(text: string, level: CefrLevel) {
  const supabase = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_KEY!)
  ...
}
```

**Parallelism — Promise.all for independent tasks, pLimit for API calls:**

```typescript
// Independent tasks — run fully parallel
const drafts = await Promise.all(
  CEFR_LEVELS.map((level) => adaptText({ supabase, text, targetLevel: level }))
)

// External API calls — cap at 6 (Gemini rate limit threshold)
const limit = pLimit(6)
const results = await Promise.all(
  drafts.map((draft) => limit(() => synthesizeWithAlignment({ ...draft, supabase })))
)
```

**Gemini paragraph index — always normalise:**

```typescript
// ✅ — Gemini sometimes omits index; Zod throws without it
const paragraphs = raw.paragraphs.map((p, i) => ({ ...p, index: p.index ?? i }))
```

**DeepInfra response — strip data URI prefix before decoding:**

```typescript
// ✅
const base64 = result.audio.replace(/^data:audio\/[^;]+;base64,/, "")
const buffer = Buffer.from(base64, "base64")

// ❌ — result.audio is not raw base64; produces corrupted MP3
const buffer = Buffer.from(result.audio, "base64")
```

**Gemini structured output — always set responseMimeType:**

```typescript
generationConfig: {
  responseMimeType: "application/json",  // required — omitting wraps output in ```json fences
  responseSchema: { ... },
}
```

## Success Criteria

Done when:

- `pnpm -r build` — zero errors
- `pnpm pipeline generate --level B1 --category travel --lang en --words 150` — runs end-to-end
- New DB field: migration exists, RPC updated, types updated, step writes the field
- Deleted files removed from all imports
