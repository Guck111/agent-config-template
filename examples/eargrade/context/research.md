# Research: Eargrade

Background knowledge about the product, market, and users.
This file is context — not a skill. The agent reads it for understanding,
not as a pattern to apply directly to code.

---

## Product

**Eargrade** ("Level up your ear") — AI-first mobile English learning app
for commuters. Audio stories graded by CEFR level (A1–C2) with
word-synchronized transcription. Designed for listening during transit —
CarPlay and Android Auto are first-class features, not additions.

Target user: working adult, B1–B2 English, 20–40 min commute daily.
Primary constraint: phone in pocket or on a car mount, not in hand.

---

## Language Acquisition Model (Krashen's Input Hypothesis)

Content is graded one level above the user's current level (i+1).
The user sets a preferred level — it's not enforced as a gate.
Comprehensible input at the right level drives acquisition; the app
provides the content, the user chooses the challenge.

Implication for the pipeline: generating at the exact requested CEFR
level matters. Off-target generation (B2 content labeled B1) undermines
the core product promise.

---

## CEFR Levels in Practice

| Level | Vocabulary | Sentence length | Target audience |
|---|---|---|---|
| A1–A2 | Top 1000 words | 6–12 words | Near-beginner |
| B1–B2 | Top 2000 words | 10–20 words | Independent user |
| C1–C2 | Unrestricted | Varied, native-like | Advanced / near-native |

Speed of synthesis is also calibrated by level: slower (0.8×) for A1,
native speed (1.0×) for C1–C2.

---

## Approved Content Sources

The pipeline can import from public domain or CC BY-SA sources only.

| Source | License | Notes |
|---|---|---|
| VOA Learning English | Public domain | Safe sections only — see architecture.md |
| Simple English Wikipedia | CC BY-SA | All articles |
| Project Gutenberg | Public domain | Literary texts |

AP/Reuters content embedded in VOA news sections is **not** public domain.
The pipeline checks source URL prefix, not page content.

---

## Competitive Context

Direct competitors: Pimsleur (audio-first, expensive), Audible + language
content (not graded), LingQ (text-heavy, complex UX).

Differentiator: CEFR grading + word-level synchronised transcript +
CarPlay. No competitor does all three. Most language audio apps have no
transcript; most transcript apps have no audio sync.
