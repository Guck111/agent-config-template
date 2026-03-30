---
trigger: always_on
---

# General Development Rules

<!--
  Rules that apply across ALL domains and ALL task types.
  If a rule only applies to pipeline work or only to mobile work — it belongs
  in agent-[domain].md, not here.

  This file is always in context. Keep it lean.
  Target: 10–20 rules. Every rule should be something you've actually needed to enforce.
-->

## Code Quality

- {{LANGUAGE_RULE}}
  <!-- Example: "TypeScript exclusively. No JavaScript files in src/." -->

- {{TYPING_RULE}}
  <!-- Example: "No `any`. If the type is unknown, use `unknown` and narrow it." -->

- {{BUILD_RULE}}
  <!-- Example: "Run `pnpm -r build` after every source change. Don't test what hasn't compiled." -->

- {{LINT_RULE}}
  <!-- Example: "Zero lint warnings in committed code. Fix, don't suppress." -->

## Dependencies

- {{INSTALL_RULE}}
  <!-- Example: "Check if a package is already in package.json before installing." -->

- {{VERSION_RULE}}
  <!-- Example: "Don't upgrade transitive dependencies without understanding why they're pinned." -->

- {{NATIVE_DEP_RULE}}
  <!-- Example: "Native packages: use `npx expo install`, not `pnpm add`. See skills.md." -->

## File Structure

- {{IMPORT_RULE}}
  <!-- Example: "Shared types live in `packages/types`. Never redefine them in app or pipeline code." -->

- {{DEAD_CODE_RULE}}
  <!-- Example: "Delete files you're replacing, not just the content. Remove their imports." -->

- {{SCHEMA_RULE}}
  <!-- Example: "Schema changes go in migration files. Never ALTER TABLE in application code." -->

## Error Handling

- {{ERROR_RULE_1}}
  <!-- Example: "Catch errors at the step boundary, not inside pure functions." -->

- {{ERROR_RULE_2}}
  <!-- Example: "Log the original error before re-throwing. Don't swallow stack traces." -->

## Security

- {{SECRET_RULE}}
  <!-- Example: "Never commit secrets. Use .env files. Check .env.example is up to date." -->

- {{CLIENT_SECRET_RULE}}
  <!-- Example: "Never expose service-role keys or private API keys to the client." -->

## {{CUSTOM_SECTION_NAME}}

<!--
  Add project-specific rule categories here.
  Examples: "Database", "Testing", "API", "Deployment"
-->

- {{CUSTOM_RULE_1}}
- {{CUSTOM_RULE_2}}
