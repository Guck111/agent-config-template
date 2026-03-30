# {{PROJECT_NAME}}

{{PROJECT_DESCRIPTION}}
<!-- One sentence. What the project does and who it's for. -->

## Commands

```bash
# {{COMMAND_1_DESCRIPTION}}
{{COMMAND_1}}

# {{COMMAND_2_DESCRIPTION}}
{{COMMAND_2}}

# {{COMMAND_3_DESCRIPTION}}
{{COMMAND_3}}
```

<!--
  List the 3–5 commands used most often in development.
  The agent will suggest running these without needing to look them up.
  Example:
    pnpm -r build                    # build all packages
    pnpm pipeline generate ...       # run pipeline
    pnpm --filter @repo/mobile start # dev server
-->

## Agent context

@.claude/agents/role.md
@.claude/agents/instructions.md
@.claude/agents/architecture.md
@.claude/agents/skills.md
@.claude/agents/agent-{{DOMAIN_1}}.md
@.claude/agents/workflows/{{WORKFLOW_1}}.md
@.claude/context/reference.md

<!--
  Add one @-import per file created in .claude/agents/ and .claude/context/.
  The installer (install.sh) generates this list automatically.
  Only update manually if you add or remove files after initial install.

  Domain agents use glob triggers — list all of them here so CLAUDE.md
  knows they exist, even though they only activate for matching file paths.
-->
