# Reference: Eargrade

Single source of truth for facts the agent needs during a session.
If something is here, it is not restated anywhere else.

---

## Environment Variables

### Supabase

```
SUPABASE_URL=project URL (safe for mobile client)
SUPABASE_ANON_KEY=anonymous key (safe for mobile client)
SUPABASE_SERVICE_ROLE_KEY=service role key — pipeline only, NEVER expose to mobile
```

### AI Services (pipeline only)

```
GEMINI_API_KEY=Gemini 2.5 Flash Lite — story generation and CEFR adaptation
DEEPINFRA_API_KEY=DeepInfra Kokoro-82M — TTS synthesis + word alignment
```

### Pipeline runtime

```
SYSTEM_USER_ID=UUID of the reserved system profile row (pipeline-authored content)
```

---

## Database Schema

Six tables. RLS enabled on all.

### `profiles`

```sql
id                    UUID  PK (= auth.users.id)
native_language       CHAR(2)
preferred_cefr_level  TEXT        -- A1..C2, last used level (not a gate)
target_language       CHAR(2)     DEFAULT 'en'
created_at            TIMESTAMPTZ
```

One row per Supabase Auth user + one reserved system row (`SYSTEM_USER_ID`) for pipeline-authored content.

### `articles`

```sql
id            UUID  PK DEFAULT gen_random_uuid()
title         TEXT  NOT NULL
source_type   TEXT  CHECK (source_type IN ('generated', 'url'))
source_url    TEXT                -- null for generated articles
source_title  TEXT                -- null for generated articles
category      TEXT
created_at    TIMESTAMPTZ DEFAULT now()
```

### `story_variants`

```sql
id          UUID  PK DEFAULT gen_random_uuid()
article_id  UUID  REFERENCES articles(id) ON DELETE CASCADE
cefr_level  TEXT  CHECK (cefr_level IN ('A1','A2','B1','B2','C1','C2'))
body        TEXT  NOT NULL        -- full story text
audio_url   TEXT  NOT NULL        -- public Supabase Storage URL
alignment   JSONB NOT NULL        -- Array<{ word, start, end, spaceAfter }>
created_at  TIMESTAMPTZ DEFAULT now()
```

### `word_translations`

```sql
word          TEXT    NOT NULL
native_lang   CHAR(2) NOT NULL
translations  TEXT[]  NOT NULL
PRIMARY KEY (word, native_lang)
```

### `sentence_translations`

```sql
variant_id      UUID    REFERENCES story_variants(id) ON DELETE CASCADE
sentence_index  INT     NOT NULL
native_lang     CHAR(2) NOT NULL
translation     TEXT    NOT NULL
PRIMARY KEY (variant_id, sentence_index, native_lang)
```

### `listening_progress`

```sql
user_id          UUID  REFERENCES profiles(id)
variant_id       UUID  REFERENCES story_variants(id)
last_position_sec FLOAT NOT NULL DEFAULT 0
updated_at        TIMESTAMPTZ DEFAULT now()
PRIMARY KEY (user_id, variant_id)
```

---

## Atomic Persistence RPC

```sql
-- All pipeline content inserts go through this function
insert_article_with_variants(p_article JSONB, p_variants JSONB) RETURNS UUID
```

Called once at the end of every pipeline run. Rolls back entirely on any failure.
Never call `persistArticle` and `persistVariant` separately.

---

## API Contracts

### DeepInfra — Kokoro-82M (synthesis + alignment)

**Request:**
```typescript
POST https://api.deepinfra.com/v1/inference/hexgrad/Kokoro-82M
Authorization: bearer ${DEEPINFRA_API_KEY}

{
  text: string,
  preset_voice: [string],   // e.g. ["af_heart"]
  speed: number,            // 0.8 (A1) – 1.0 (C1/C2)
  output_format: "mp3",
  return_timestamps: true
}
```

**Response:**
```typescript
{
  audio: string,  // "data:audio/mp3;base64,<base64data>" — NOT raw base64
  words: Array<{ text: string; start: number; end: number }>
}
```

**Gotchas:**
- `audio` includes a data URI prefix — strip it before decoding:
  `result.audio.replace(/^data:audio\/[^;]+;base64,/, "")`
- Cap concurrency to 6 parallel calls with `pLimit(6)` — silent failures above that

### Gemini — 2.5 Flash Lite (generation + adaptation)

**Request (structured output):**
```typescript
generationConfig: {
  responseMimeType: "application/json",  // REQUIRED — omit and output is wrapped in ```json fences
  responseSchema: { ... }
}
```

**Gotchas:**
- Always set `responseMimeType: "application/json"` — without it `JSON.parse` throws
- Paragraph `index` may be missing from response — always normalise: `p.index ?? i`

---

## Zod Types (`packages/types/src/story.ts`)

```typescript
type CefrLevel = 'A1' | 'A2' | 'B1' | 'B2' | 'C1' | 'C2'

type Category = 'travel' | 'science' | 'history' | 'culture' | 'technology' | 'general'
// 'general' is used for imported articles

interface StoryDraft {
  title: string
  cefr_level: CefrLevel
  paragraphs: Array<{ index: number; text: string }>
  vocabulary_hints: string[]
}

interface AlignmentWord {
  word: string
  start: number
  end: number
  spaceAfter: boolean
}

// AlignmentSchema = z.array(AlignmentWordSchema)
// ArticleSchema — maps to articles table
// StoryVariantSchema — maps to story_variants table
```

---

## File Structure

```
apps/mobile/
  app/                      ← Expo Router screens (file = route)
  src/
    components/             ← shared UI components
    hooks/
      useAudioPlayer.ts     ← all TrackPlayer logic lives here
    store/
      articles.ts           ← articlesStore + actions
      profile.ts            ← profileStore + actions
    navigation/             ← navigator config

packages/pipeline/
  src/
    steps/                  ← pure step functions (one per pipeline stage)
      adaptText.ts
      synthesizeWithAlignment.ts
      persistArticleWithVariants.ts
    references/             ← CEFR reference JSON (a1.json … c2.json)
    utils/
      annotateSpacing.ts
  supabase/                 ← migration SQL files (migration_NNN_*.sql)

packages/types/
  src/
    story.ts                ← all shared Zod schemas + derived types
```

---

## Key Commands

```bash
# Build all packages (run after any source change)
pnpm -r build

# Run pipeline — generate mode
pnpm pipeline generate --level B1 --category travel --lang en --words 300

# Run pipeline — import mode
pnpm pipeline import --url https://learningenglish.voanews.com/a/...

# Start mobile dev server
pnpm --filter @repo/mobile start

# Find dead code and unused exports
pnpm knip --no-config-hints

# Verify react-native version after native installs
cat apps/mobile/node_modules/react-native/package.json | grep '"version"'
# Expected: 0.76.x
```
