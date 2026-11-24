---
id: ADR-004
type: adr
title: Schemas — Zod-first, dates as strings, discriminated unions, additive-only, committed JSON Schema
stage: architecture
status: accepted
superseded_by:
version: 3
refs: [REQ-020, REQ-031, REQ-023]
visibility: internal
author: architect
updated: 2026-11-24
---

## Context

Schemas validate document frontmatter (REQ-020, 26 doc types) and the CLI values core owns (ADR-003),
and must emit the same `details: [{ path, message }]` shape. REQ-031 needs JSON Schema as a real
artifact (`spine next --json` validates against it). Immutable records (REQ-023) must stay valid as
schemas evolve.

## Options

| Choice | Options | Decision |
| --- | --- | --- |
| Source | Zod-first (Zod 4) · JSON-Schema-first (Ajv) · TypeBox | **Zod-first**, Zod 4 pinned |
| JSON Schema role | generated & contract-tested · docs only | **generated, committed, contract-tested** |

## Decision

**Zod-first (Zod 4, pinned).**

- **Dates are strings:** `z.iso.date()` / `z.iso.datetime()`, never `z.date()` (not exportable to JSON
  Schema). The YAML parser chosen in Topic 5 must load dates as strings (no auto `Date` coercion).
- **Frontmatter is a discriminated union on `type`:** a shared base plus one **strict** object per doc
  type, so a misspelled key (`stauts`) fails with a precise path.
- **Additive-only evolution:** new fields are optional; old fields are deprecated, never removed or
  renamed — so immutable records stay valid without rewriting (REQ-023). Additive-only begins at the
  **switch-over**; before that, a **single migration pass** fixes the hand-written bootstrap docs,
  whose frontmatter predates the schemas.
- **Error format:** Zod issues map to `details: [{ path, message, code }]` (the ADR-003 shape).

**JSON Schema as a generated, committed artifact.**

- Generate from Zod with **`unrepresentable: "throw"`**, so a schema that can't be exported breaks the
  build.
- **Commit** the generated files under `schemas/` (not only `dist/`); a check fails when they differ
  from a fresh export, so schema changes appear in the phase PR diff for review.
- **Ajv is a devDependency**, used only by the contract test, on its 2020-12 build (`ajv/dist/2020`)
  to match Zod's default target.
- `.refine()` / `.superRefine()` checks do **not** appear in JSON Schema, so Zod stays stricter than
  the artifact. Keep refinements **rare** and list each one in the register below.

### Refinements register (Zod stricter than the exported JSON Schema)
<!-- Add every .refine()/.superRefine() here as it is introduced, so the Zod↔artifact gap stays visible. -->
- (none yet)

## Consequences

- **Easier:** one source for types, validation and the artifact; precise field-level errors; committed
  schemas make schema change reviewable in PRs; immutable records never need rewriting.
- **Harder:** the generate → commit → diff-check must stay green; the discriminated union means every
  doc type needs its own strict object; refinements are invisible in the artifact (documented in the
  register); dates-as-strings constrains the YAML loader.
- **Must now be true:** the YAML parser keeps dates as strings; the schemas phase builds the Zod schemas
  (discriminated union on `type`), the generate/commit/diff check, and the Ajv contract test; a
  one-time migration of the bootstrap docs' frontmatter runs before switch-over (a plan item). Phases:
  see `I01-PLAN`'s ADR→phase table.
- **Amended 2026-11-23:** phase numbers removed.
- **Amended 2026-11-24:** visibility → internal (every spine ADR is internal; ADR-018).
