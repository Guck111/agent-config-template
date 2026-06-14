<!--
  Eargrade example — @-import variant (Claude Code runtime format).

  This is what `adapters/claude-code/convert.sh` generates: a thin CLAUDE.md that
  @-imports the installed files under .claude/agents/ and .claude/context/. It's
  valid and works at Claude Code runtime, but on its own it shows only the index,
  not the content.

  For the self-contained reference — every rule, agent, and pattern inlined — see
  CLAUDE.md in this directory. That one is the "what a finished config looks like"
  example; this one is the "what the installer writes" example.
-->

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

@.claude/agents/role.md
@.claude/agents/instructions.md
@.claude/agents/architecture.md
@.claude/agents/skills.md
@.claude/agents/agent-pipeline.md
@.claude/agents/agent-mobile.md
@.claude/agents/workflows/pipeline-feature.md
@.claude/agents/workflows/mobile-feature.md
@.claude/context/reference.md