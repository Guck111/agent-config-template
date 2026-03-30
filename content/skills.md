---
trigger: always_on
---

# Skills: When X → Do Y

<!--
  Each entry answers: "I need to do X — how exactly do I do it in THIS project?"

  Format for each skill:
  - Trigger condition (when does this apply?)
  - Correct implementation (what to do)
  - Code example — ✅ correct, ❌ wrong (if the wrong version is plausible)
  - Why the wrong version fails (if not obvious)

  Rules for this file:
  - No library lists. "We use X" is not a skill.
  - No generic best practices. Skills are project-specific.
  - Every skill should come from a real session mistake or a real gotcha.
  - Run skill-workshop periodically to find new candidates.

  Organise by domain area. Suggested sections below — rename or replace as needed.
-->

---

## {{SKILL_CATEGORY_1}}
<!-- Example: "UI Components", "API Calls", "State Management" -->

**When {{SKILL_1_TRIGGER}}:**
<!-- Example: "When styling a component:" -->

{{SKILL_1_DESCRIPTION}}
<!-- One to three sentences explaining what to do and why. -->

```{{LANGUAGE}}
// ✅
{{SKILL_1_CORRECT_CODE}}

// ❌
{{SKILL_1_WRONG_CODE}}
```
<!-- If there's no plausible wrong version, omit the ❌ block. -->

---

**When {{SKILL_2_TRIGGER}}:**

{{SKILL_2_DESCRIPTION}}

```{{LANGUAGE}}
// ✅
{{SKILL_2_CORRECT_CODE}}
```

---

## {{SKILL_CATEGORY_2}}
<!-- Example: "Database", "External APIs", "File Handling" -->

**When {{SKILL_3_TRIGGER}}:**

{{SKILL_3_DESCRIPTION}}

```{{LANGUAGE}}
// ✅
{{SKILL_3_CORRECT_CODE}}

// ❌ — {{SKILL_3_WHY_WRONG}}
{{SKILL_3_WRONG_CODE}}
```

---

## Dependencies

<!--
  Package installation rules specific to this project.
  These are almost always worth including — wrong install commands
  are a top source of hard-to-debug failures.
-->

**When adding a dependency:**

```bash
# ✅ — {{CORRECT_INSTALL_COMMAND_DESCRIPTION}}
{{CORRECT_INSTALL_COMMAND}}

# ❌ — {{WRONG_INSTALL_COMMAND_DESCRIPTION}}
{{WRONG_INSTALL_COMMAND}}
```

<!--
  Example:
  **When adding a native package (React Native / Expo):**

  ```bash
  # ✅ — Expo resolves the correct version for your SDK
  npx expo install react-native-track-player

  # ❌ — pnpm resolves independently, may pull incompatible version
  pnpm add react-native-track-player
  ```
-->

---

<!--
  ADDING SKILLS OVER TIME:
  After each project phase, run skill-workshop to identify candidates:

    git clone https://github.com/grayodesa/skill-workshop ~/.skill-workshop
    cp ~/.skill-workshop/agents/* ~/.claude/agents/
    cp -r ~/.skill-workshop/skills/* ~/.claude/skills/
    # Then in Claude Code:
    /skill-workshop

  Score 60+ with 2+ sessions → add to this file.
-->
