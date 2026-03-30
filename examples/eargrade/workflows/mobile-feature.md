---
description: Mobile Feature Development Workflow
---

# Mobile Feature Workflow

Every feature in `apps/mobile` falls into one of three types.
Identify the type first — it determines the exact steps to follow.

| Type | Description | Examples |
|---|---|---|
| **UI-only** | New screen or component, no new data | Onboarding screen, settings UI |
| **Data feature** | Reads or writes to store / Supabase | Article list, playback progress, translations |
| **Audio feature** | Involves TrackPlayer or Transcript | Word highlighting, speed control, pre-roll |

---

## Type 1 — UI-only feature

```
Create component/screen
  → Add to Expo Router (if new screen)
  → Style with createStyleSheet + useStyles
  → Verify on simulator
```

### Steps

**1. Create the file**
- Screens go in `apps/mobile/app/` (Expo Router file-based routing)
- Reusable components go in `apps/mobile/src/components/`

**2. Routing (new screens only)**
- File name = route segment: `app/settings/index.tsx` → `/settings`
- Nested routes: `app/article/[id].tsx` → `/article/:id`
- Modal: wrap with `<Stack.Screen options={{ presentation: 'modal' }} />`

**3. Styling**
Always use `createStyleSheet` + `useStyles`. Never hardcode values.
```typescript
import { createStyleSheet, useStyles } from "react-native-unistyles"

export default function MyScreen() {
  const { styles } = useStyles(stylesheet)
  return <View style={styles.container} />
}

const stylesheet = createStyleSheet((theme) => ({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
    padding: theme.spacing.m,
  },
}))
```

Available tokens: `theme.colors.*`, `theme.spacing.*`, `theme.radius.*`, `theme.typography.*`.

**4. Done when**
- Renders correctly in light + dark theme (adaptiveThemes is on by default)
- No TypeScript errors
- No hardcoded color or spacing values

---

## Type 2 — Data feature

```
Define store shape
  → Add store action (reads/writes Legend-State)
  → Add Supabase query inside the action (not in the component)
  → Wrap component in observer()
  → Connect component to store
  → Verify offline behaviour
```

### Steps

**1. Define store shape** in `apps/mobile/src/store/`

If the data belongs to an existing store (e.g. `articlesStore`, `profileStore`), extend it.
If it's a new domain, create `apps/mobile/src/store/<domain>.ts`.
```typescript
import { observable } from "@legendapp/state"
import { persistObservable } from "@legendapp/state/persist"

export const myStore = observable({
  items: [] as MyItem[],
  selectedId: null as string | null,
})

// Persist to AsyncStorage if data must survive app restart
persistObservable(myStore, { local: "my-store-key" })
```

**2. Add store actions** — Supabase calls go inside actions, never in components
```typescript
export const myStoreActions = {
  async fetchItems() {
    const { data, error } = await supabase
      .from("story_variants")
      .select("*")
      .eq("status", "public")

    if (error) throw error
    myStore.items.set(data)
  },

  async updateProgress(variantId: string, position: number) {
    // Write to Legend-State FIRST
    myStore.progress[variantId].set({ position, updatedAt: Date.now() })
    // Supabase sync happens separately on reconnect — do not await here
  },
}
```

**3. Wrap component with `observer()`**
```typescript
import { observer } from "@legendapp/state/react"

const ArticleList = observer(() => {
  const items = articlesStore.list.get()  // reactive — re-renders on change
  // ...
})

export default ArticleList
```

**4. Validate data with Zod**
All data from Supabase must be parsed through the relevant schema from `@repo/types`
before storing. Never store unvalidated API responses.
```typescript
import { ArticleSchema } from "@repo/types"
const parsed = ArticleSchema.array().parse(data)
myStore.items.set(parsed)
```

**5. Done when**
- Works with no network (offline-first: Legend-State has the data)
- Works after restart (persistObservable survives app kill)
- Supabase query runs only in store action, not in component
- All data passes through Zod schema

---

## Type 3 — Audio feature

```
Verify TrackPlayer is set up via ensureSetup()
  → Modify useAudioPlayer hook (if behaviour change)
  → Update Transcript component (if word highlighting change)
  → Verify on device (simulator audio is unreliable)
```

### Steps

**1. TrackPlayer setup**
Never call `TrackPlayer.setupPlayer()` directly. Always go through `ensureSetup()`:
```typescript
// ensureSetup() is a module-level singleton — call it, don't reimplement it
await ensureSetup()
```

**2. Modifying playback behaviour**
Changes to play/pause/seek/speed go in `useAudioPlayer.ts`, not in screen components.
Screen components call hook methods; they don't call TrackPlayer directly.
```typescript
// ✅ Screen calls the hook
const { togglePlayback, seek, setSpeed } = useAudioPlayer()

// ❌ Screen calls TrackPlayer directly
await TrackPlayer.pause()
```

**3. Word highlighting in Transcript**
The active word is found by scanning `alignment: Array<{ word, start, end }>` for the
entry where `start <= currentPosition < end`.

Use a pointer that advances forward — do not linear-scan from index 0 on every frame:
```typescript
// Move pointer forward as audio progresses
while (
  activeIndex < alignment.length - 1 &&
  alignment[activeIndex + 1].start <= currentPosition
) {
  activeIndex++
}
```

Auto-scroll to the active word fires only when `isAutoScrollEnabled` is true.
Set `isAutoScrollEnabled = false` when the user manually scrolls; restore on play resume.

**4. CarPlay / Android Auto**
If the feature involves playback controls visible in Drive Mode:
- Use only `CPListTemplate` and `CPNowPlayingTemplate`
- No custom layouts, no animations, no modals
- Test with the CarPlay simulator in Xcode

**5. Done when**
- Tested on a real device or Xcode simulator (not just Metro)
- No "already setup" TrackPlayer errors in console
- Word highlight advances correctly through the transcript
- Auto-scroll disables on manual scroll, re-enables on play

---

## Cross-cutting: adding a new dependency

```bash
# Anything with native code or in the Expo ecosystem
npx expo install <package-name>

# Pure JS only (no native bindings)
pnpm add <package-name>
```

After installing a native package, verify `react-native` version:
```bash
cat apps/mobile/node_modules/react-native/package.json | grep '"version"'
# Expected: 0.76.x — if 0.79.x, find what pulled it and reset
```

---

## Cross-cutting: connecting to a new Supabase table

1. Confirm the table has RLS enabled and the correct SELECT policy
2. Add the Zod schema to `packages/types/src/story.ts`
3. Run `pnpm -r build` to propagate the new type
4. Add a store action that queries the table and validates with Zod
5. Never query Supabase from a component directly
