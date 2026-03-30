---
trigger: always_on
---

# Architecture: Thin Client Strategy

## Core Principle

The mobile application is a **Thin Client**. It must **NEVER** contain logic
for content generation, voice synthesis, or text alignment. Its sole purpose
is to fetch, store (offline-first), and render data provided by the backend.

## Division of Concerns

### Content Pipeline (`packages/pipeline`)

**Owns:**
- Content generation via Gemini 2.5 Flash Lite (AI story generation or CEFR adaptation)
- Voice synthesis and word-level alignment via DeepInfra Kokoro-82M
- Atomic persistence of articles and variants to Supabase via RPC

**Must never:**
- Run inside the mobile app or be triggered by a user interaction directly
- Expose pipeline secrets (`GEMINI_API_KEY`, `DEEPINFRA_API_KEY`) outside Node.js scripts

### Mobile App (`apps/mobile`)

**Owns:**
- UI rendering via React Native / Expo + react-native-unistyles
- Offline-first state management via Legend-State + persistObservable
- Synchronized audio playback (word highlight matched to audio position)
- Interaction logic (tap → word translation, long press → sentence translation)
- CarPlay / Android Auto via react-native-track-player system templates only

**Must never:**
- Generate, synthesize, or adapt content
- Write directly to Supabase from a UI interaction (use store actions)
- Import or call AI SDKs of any kind

### Shared Types (`packages/types`)

**Owns:**
- Zod schemas for all data structures crossing package boundaries
- Derived TypeScript types (`z.infer<typeof ...>`)

**Must never:**
- Contain business logic, API calls, or side effects

## Data Flow

```
[Pipeline scripts]
      │ generates content
      ▼
[Supabase DB + Storage]
      │ fetches on demand
      ▼
[Legend-State store]   ←── write layer for all user state
      │ renders
      ▼
[React Native UI]
```

User-generated data (progress, translations) flows:
```
[UI interaction] → [store action] → [Legend-State] → [Supabase sync on reconnect]
```

Direct writes from UI to Supabase are forbidden.

## Atomic Persistence

All content inserts go through a single Postgres RPC:

```sql
insert_article_with_variants(p_article JSONB, p_variants JSONB) RETURNS UUID
```

If any pipeline step fails before this call, nothing is written to the database.
If the RPC itself fails, Postgres rolls back the entire transaction.
No orphaned article rows. No variants without an article.

Calling `persistArticle` and `persistVariant` separately is **not permitted** —
even when it seems like it would work. Atomicity is the point.

## Pipeline Modes

The pipeline always produces the same output: 1 article row + N variant rows,
persisted atomically. The input source determines the mode.

| Mode | Command | Output |
|---|---|---|
| Generate | `pnpm pipeline generate --level B1 --category travel --lang en --words 300` | 1 article + 1 variant |
| Import | `pnpm pipeline import --url https://learningenglish.voanews.com/a/...` | 1 article + 6 variants (A1–C2) |

**Approved import sources (public domain / CC BY-SA only):**
- VOA Learning English — `learningenglish.voanews.com` (public domain).
  Safe sections: _Words and Their Stories_, _American Stories_, _Learning English Podcast_.
  Do not use AP/Reuters-embedded news sections.
- Simple English Wikipedia — `simple.wikipedia.org` (CC BY-SA)
- Project Gutenberg — `gutenberg.org` (public domain literary texts)

## Restrictions for AI Agent

> [!CAUTION]
>
> - **DO NOT** install AI-related SDKs in `apps/mobile`.
> - **DO NOT** write content generation or adaptation logic in `apps/mobile`.
> - **DO NOT** call `persistArticle` and `persistVariant` separately — always `persistArticleWithVariants`.
> - **DO NOT** use AP/Reuters news content from VOA — only VOA-original sections.
> - **DO NOT** add new data fields without a migration. Never ALTER TABLE in application code.
> - **IF** a new data field is needed in the mobile app, assume it will be provided by the pipeline.
