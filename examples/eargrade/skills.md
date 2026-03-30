---
trigger: always_on
---

# Skills: When X → Do Y

Concrete patterns for this codebase. Each entry answers:
"I need to do X — how exactly do I do it in Eargrade?"

---

## Mobile UI

**When styling a component:**
Use `createStyleSheet` + `useStyles` from `react-native-unistyles`.
Never use inline style objects or `StyleSheet.create`.
Always use `theme.colors.*`, `theme.spacing.*`, `theme.radius.*` —
never hardcode values like `16`, `"#FFF"`, or `borderRadius: 8`.

```typescript
// ✅
const { styles, theme } = useStyles(stylesheet)
const stylesheet = createStyleSheet((theme) => ({
  container: { padding: theme.spacing.m, backgroundColor: theme.colors.surface },
  title: { color: theme.colors.textPrimary, fontSize: 18, fontWeight: "700" },
}))

// ❌
<View style={{ padding: 16, backgroundColor: "#1C1C1E" }} />
```

**When building a screen that reads from the store:**
Wrap the component in `observer()` from `@legendapp/state/react`.
Access store values via `.get()` inside the component body.

```typescript
// ✅
const MyScreen = observer(() => {
  const articles = articlesStore.list.get()
  return <ArticleList items={articles} />
})

// ❌ — store changes won't trigger re-render
const MyScreen = () => {
  const articles = articlesStore.list  // missing .get()
  ...
}
```

**When displaying a CEFR-filtered list:**
Always verify `cefr_level` is present before rendering. Never render an article
card without a confirmed level — the badge component throws on `undefined`.

**When showing source attribution for an imported article:**
Display `source_title` and render `source_url` as a tappable link.
Never show "Eargrade" as the source for `source_type === 'url'` articles.

---

## State & Storage

**When writing playback progress or user vocabulary:**
Write to Legend-State first. Supabase sync happens on reconnect.
Never call Supabase directly from a UI event.

```typescript
// ✅ — store handles offline persistence and sync
articlesStore.updateProgress(variantId, position)

// ❌ — bypasses offline-first layer, breaks when offline
await supabase.from('listening_progress').upsert({ variant_id, last_position_sec })
```

**When fetching a word translation (long press on word):**
Query `word_translations` by `(word, native_lang)`. Returns `TEXT[]`.
Clean the word before querying: lowercase, strip non-alphanumeric except internal apostrophes.

```typescript
const cleanWord = word.toLowerCase().replace(/[^a-z0-9']/g, "")
const { data } = await supabase
  .from("word_translations")
  .select("translations")
  .eq("word", cleanWord)
  .eq("native_lang", nativeLang)
  .single()
```

**When fetching a sentence translation (long press on sentence):**
Query `sentence_translations` by `(variant_id, sentence_index, native_lang)`.
Use `sentence_index` — not the sentence text. Text is unstable across variants.

---

## Audio

**When setting up TrackPlayer:**
Call `ensureSetup()` — a module-level singleton promise — before any TrackPlayer operation.
Never call `TrackPlayer.setupPlayer()` directly in a component.

```typescript
// ✅ — singleton, safe to call multiple times
await ensureSetup()
await TrackPlayer.add({ url: audioUrl, title, artist: "Eargrade" })

// ❌ — multiple components calling setupPlayer() race and throw "already setup"
await TrackPlayer.setupPlayer()
```

**When implementing word highlighting in Transcript:**
Find the active word by scanning `alignment: Array<{ word, start, end }>`
for the entry where `start <= currentPosition < end`.
Advance a pointer forward — do not linear-scan from index 0 on every frame.

```typescript
// ✅ — O(1) per frame after initial seek
while (
  activeIndex < alignment.length - 1 &&
  alignment[activeIndex + 1].start <= currentPosition
) {
  activeIndex++
}

// ❌ — O(n) on every frame, degrades on long articles
const activeIndex = alignment.findIndex(
  (w) => w.start <= currentPosition && currentPosition < w.end
)
```

**When adding CarPlay / Android Auto support:**
Use only `CPListTemplate` and `CPNowPlayingTemplate`.
No custom layouts, no animations, no modals, no banners.
Test with the CarPlay simulator in Xcode.

---

## Pipeline

**When writing a step function:**
Pure functions only — accept typed params, return typed result, throw on error.
Never instantiate `createClient` inside a step. The client is created once at
the pipeline entry point and injected as a parameter.

```typescript
// ✅
export async function adaptText(params: {
  supabase: SupabaseClient
  text: string
  targetLevel: CefrLevel
}): Promise<StoryDraft> { ... }

// ❌ — creates a new connection on every call
export async function adaptText(text: string, level: CefrLevel) {
  const supabase = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_KEY!)
  ...
}
```

**When running tasks in parallel:**
Independent tasks (same API, no shared state): `Promise.all`.
External API calls where concurrency must be capped: `pLimit`.

```typescript
// ✅ — CEFR adaptations are independent
const drafts = await Promise.all(
  CEFR_LEVELS.map((level) => adaptText({ supabase, text, targetLevel: level }))
)

// ✅ — cap DeepInfra concurrency to avoid rate-limit failures on the 7th call
const limit = pLimit(6)
const results = await Promise.all(
  drafts.map((draft) => limit(() => synthesizeWithAlignment({ ...draft, supabase })))
)
```

**When calling Gemini for structured output:**
Always set `responseMimeType: "application/json"` in `generationConfig`.
Without it, Gemini wraps the response in markdown fences — `JSON.parse` throws.

```typescript
// ✅
generationConfig: {
  responseMimeType: "application/json",
  responseSchema: { ... },
}

// ❌ — response arrives as ```json ... ``` string, not raw JSON
generationConfig: {
  responseSchema: { ... },
}
```

**When processing Gemini paragraph output:**
Always normalise `index` before parsing — Gemini sometimes omits it.

```typescript
// ✅
const paragraphs = raw.paragraphs.map((p, i) => ({ ...p, index: p.index ?? i }))

// ❌ — Zod throws on missing index fields
const paragraphs = raw.paragraphs
```

**When decoding DeepInfra audio response:**
Strip the data URI prefix before decoding. `response.audio` is not raw base64.

```typescript
// ✅
const base64 = result.audio.replace(/^data:audio\/[^;]+;base64,/, "")
const buffer = Buffer.from(base64, "base64")

// ❌ — produces a corrupted MP3
const buffer = Buffer.from(result.audio, "base64")
```

---

## Dependencies

**When adding a package that links to native iOS/Android code:**

```bash
# ✅ — Expo resolves the version compatible with SDK 52
npx expo install react-native-track-player

# ❌ — pnpm resolves independently, may pull react-native@0.79 instead of 0.76
pnpm add react-native-track-player
```

After installing a native package, verify:
```bash
cat apps/mobile/node_modules/react-native/package.json | grep '"version"'
# Expected: 0.76.x — if 0.79.x, find what pulled it and reset
```

**When adding a pure-JS package (no native bindings):**
```bash
pnpm add <package-name>
# Or for dev dependencies:
pnpm add -D <package-name>
```
