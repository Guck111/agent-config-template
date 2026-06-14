---
description: Content Pipeline Workflow
---

# Content Pipeline Workflow

Every task in `packages/pipeline` falls into one of three types.
Identify the type first — it determines the exact step order, and for schema
changes the order is non-negotiable.

| Type | Description | Examples |
|---|---|---|
| **Generate** | Produce new content from a topic/level | `generate --level B1 --category travel` |
| **Import** | Adapt content from an approved external source | `import --url <voa-article>` |
| **Schema change** | Add or change a field on a content table | New `difficulty` column, new variant field |

The first two run the same persistence path; the third changes the contract every
other step depends on, so it comes with a fixed sequence.

---

## Type 1 — Generating content

```
Read the step → build → adapt (Gemini) → synthesize + align (DeepInfra)
  → persist atomically (one RPC) → test the command end-to-end
```

### Steps

**1. Orient before touching code**
- Read the relevant step in `packages/pipeline/src/steps/`
- Check the latest migration: `packages/pipeline/supabase/migration_NNN_*.sql`
- If `@repo/types` fails to resolve, run `pnpm install` at the repo root
- Run `pnpm -r build` *before* changing anything — type errors in shared packages
  only surface at build time

**2. Keep step functions pure**
The Supabase client is created once at the pipeline entry point and injected.
Never instantiate `createClient` inside a step.
```typescript
// ✅ inject the client
export async function adaptText(params: {
  supabase: SupabaseClient
  text: string
  targetLevel: CefrLevel
}): Promise<StoryDraft> { ... }

// ❌ new connection every call → pool exhaustion under parallel load
export async function adaptText(text: string, level: CefrLevel) {
  const supabase = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_KEY!)
}
```

**3. Parallelise correctly**
`Promise.all` for independent work, `pLimit(6)` for Gemini calls — 6 is the
rate-limit threshold; the 7th fails silently.
```typescript
const limit = pLimit(6)
const results = await Promise.all(
  drafts.map((draft) => limit(() => synthesizeWithAlignment({ ...draft, supabase })))
)
```

**4. Persist atomically — one RPC, never split writes**
Always go through `persistArticleWithVariants` (the `insert_article_with_variants`
RPC). Never call `persistArticle` and `persistVariant` separately — a failure
between them leaves orphaned article rows with no variants.

**5. Build and test end-to-end**
```bash
pnpm -r build
pnpm pipeline generate --level B1 --category travel --lang en --words 150
```

**6. Done when**
- `pnpm -r build` — zero errors
- The `generate` command above runs end-to-end with no thrown errors
- No orphaned rows: every article persisted has its variants

---

## Type 2 — Importing from an external source

```
Confirm source is approved → fetch → adapt (Gemini) → synthesize + align
  → persist atomically → test the command
```

### Steps

**1. Confirm the source is allowed**
Import only from public-domain / CC BY-SA sources:
- VOA Learning English — **VOA-original sections only**, not AP/Reuters-embedded news
- Simple English Wikipedia
- Project Gutenberg

If the URL isn't one of these, stop and ask — licensing is not negotiable.

**2. Reuse the generation path**
Import differs only in the fetch step; adaptation, synthesis, alignment, and
persistence are the same code as Type 1. Don't fork the persistence logic.

**3. Carry the Gemini patterns into `fetch.ts` too**
The `responseMimeType` and paragraph-index rules (see Cross-cutting) apply to the
`fetch.ts` fallback, not just `adapt.ts`. The bug that appeared in `fetch.ts` was
the pattern not being carried over when it was added later.

**4. Test the command**
```bash
pnpm -r build
pnpm pipeline import --url https://learningenglish.voanews.com/a/...
```

**5. Done when**
- The `import` command runs end-to-end
- Content persisted through the same atomic RPC as generated content

---

## Type 3 — Adding a field to `articles` or `story_variants`

```
migration (column) → migration (RPC) → Zod schema → pipeline step → build + test
```

This order is non-negotiable. Types must reflect the schema, never the reverse.

### Steps

**1.** Write `migration_NNN_<description>.sql` — `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`

**2.** Update the `insert_article_with_variants` RPC in a new `migration_NNN_rpc_*.sql`
— the field has to flow through the atomic insert, or it's silently dropped

**3.** Update the Zod schema in `packages/types/src/story.ts`

**4.** `pnpm -r build` — propagate the type before any step references it

**5.** Update the pipeline step that writes the field

**6.** `pnpm -r build` → test run with `pnpm pipeline generate ...`

**Done when:** migration exists, RPC updated, types updated, the step writes the
field, and a generate run persists it end-to-end.

---

## Cross-cutting: Gemini calls

**Always set `responseMimeType`** — omit it and the output is wrapped in ```` ```json ````
fences and `JSON.parse` throws:
```typescript
generationConfig: {
  responseMimeType: "application/json",
  responseSchema: { ... },
}
```

**Always normalise the paragraph index** — Gemini sometimes omits `index`, and Zod
throws (alignment breaks silently on the affected paragraphs) without it:
```typescript
const paragraphs = raw.paragraphs.map((p, i) => ({ ...p, index: p.index ?? i }))
```

## Cross-cutting: DeepInfra audio

Strip the data-URI prefix before decoding — `result.audio` is not raw base64, and
decoding it directly produces a corrupted MP3:
```typescript
const base64 = result.audio.replace(/^data:audio\/[^;]+;base64,/, "")
const buffer = Buffer.from(base64, "base64")
```

## Cross-cutting: `@repo/types` won't resolve

```
Error: Cannot find module '@repo/types'
```
Not a code bug — stale pnpm symlinks. Run `pnpm install` at the monorepo root.
Verify: `ls -la apps/mobile/node_modules/@repo/types` should be a symlink.
