# Eargrade — Level up your ear

AI-first mobile English learning app. Audio stories graded by CEFR level (A1–C2),
word-synchronized transcription, CarPlay/Android Auto support.

**Monorepo:** `apps/mobile` (React Native/Expo) + `packages/pipeline` (Node.js) + `packages/types` (shared Zod schemas)

## Commands

```bash
pnpm -r build                                                        # build all packages
pnpm pipeline generate --level B1 --category travel --lang en --words 300
pnpm pipeline import --url https://learningenglish.voanews.com/a/...
pnpm --filter @repo/mobile start                                     # dev server
pnpm knip --no-config-hints                                          # dead code
```

## Agent context

@.agents/rules/role.md
@.agents/rules/instructions.md
@.agents/rules/architecture.md
@.agents/rules/skills.md
@.agents/workflows/content-pipeline.md
@.agents/context/reference.md
