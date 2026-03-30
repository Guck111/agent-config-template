---
trigger: always_on
---

# General Development Rules

## Code Quality

- TypeScript exclusively. No JavaScript files in `src/` directories.
- No `any`. If the type is unknown, use `unknown` and narrow it.
- Run `pnpm -r build` after every source change. Don't test what hasn't compiled.
- Zero lint warnings in committed code. Fix, don't suppress with `// eslint-disable`.

## Dependencies

- Check `package.json` before installing — the package may already be present.
- Don't upgrade transitive dependencies without understanding why they're pinned.
- Native packages (anything that links to iOS/Android native code): use `npx expo install`, not `pnpm add`. See skills.md.
- Don't patch third-party libraries. Patches mask version conflicts and break on clean installs.

## File Structure

- Shared types live in `packages/types/src/`. Never redefine them in `apps/mobile` or `packages/pipeline`.
- Delete files you're replacing, not just the content. Remove their imports.
- Schema changes go in `packages/pipeline/supabase/migration_NNN_*.sql`. Never ALTER TABLE in application code.
- One migration per logical change. Don't batch unrelated schema changes.

## Error Handling

- Catch errors at the step boundary in the pipeline, not inside pure step functions.
- Log the original error before re-throwing. Don't swallow stack traces.
- Supabase error code `PGRST116` means "no rows found" — handle it explicitly, don't throw.

## Security

- Never commit `.env` files. `.env.example` must stay up to date with every new variable.
- `DEEPINFRA_API_KEY`, `GEMINI_API_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` are pipeline-only.
  They must never appear in `apps/mobile` code or Expo config.

## Monorepo

- Run `pnpm install` at the repo root after pulling changes — stale symlinks cause
  `Cannot find module @repo/types` errors that look like code bugs.
- `pnpm -r build` builds all packages in dependency order. Run it, not per-package builds.
- `knip` finds unused exports and dead code: `pnpm knip --no-config-hints`.
