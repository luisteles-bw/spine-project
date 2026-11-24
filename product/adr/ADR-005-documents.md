---
id: ADR-005
type: adr
title: Documents — yaml (1.2) parsing, line-scan headings, per-command id index, derived graph.json
stage: architecture
status: accepted
superseded_by:
version: 3
refs: [REQ-020, REQ-021, SEC-008]
visibility: internal
author: architect
updated: 2026-11-24
---

## Context

Documents are YAML frontmatter + a Markdown body, read and written by both agents and the spine. The
spine must validate frontmatter and required headings (REQ-020), resolve references by id and flag
dangling ones (REQ-021), and must never execute untrusted content — documents can carry client text
(SEC-008).

## Decision

**Frontmatter / YAML — `yaml` (eemeli) + a tiny splitter.** gray-matter is rejected twice: its
js-yaml default uses YAML 1.1 and coerces `2026-11-22` to a `Date` (breaks ADR-004), and its built-in
JS engine `eval`s `---js` frontmatter — unacceptable when docs carry client text (SEC-008).

- Parse with explicit options — `version: '1.2'`, `schema: 'core'`, `uniqueKeys: true`, `strict: true`
  — so a future default change cannot affect us.
- The splitter strips a leading BOM, converts CRLF→LF, and matches a `---` block **only at the very
  start** of the file. Ship `.gitattributes` with `eol=lf`.
- Frontmatter edits (`status`, `updated`, …) use `parseDocument` and edit **in place**, preserving key
  order and comments, so each change is a one-line diff.
- `version` is an **integer** — unquoted `1.10` would parse as the number `1.1`.

**Required headings — line scan, skipping code fences.**

- ATX headings only (≤3 leading spaces). Fences open with ``` or ~~~ and close with the same character,
  at least as long. Match the exact heading text at the exact level.
- Each doc type's required headings live in **one registry, next to its Zod schema**.
- A required section is **empty** if it holds only whitespace or HTML comments, and empty **fails** — so
  a doc left as the untouched template (guidance lives in HTML comments) fails the check.

**id→path index & references — rebuilt per command.**

- Scan only explicit roots under `project/`, never `code/`. Read `id` from `.md` frontmatter and
  `.yaml` docs (e.g. `increment.yaml`).
- Sort paths by plain **code-unit** comparison (not `localeCompare`, whose order is locale-dependent).
- Duplicate id → hard error (exit 2). Only **frontmatter** refs resolve; ids in body text are ignored.
- Dangling refs are **warnings on drafts** but **block at gates**, so a draft may point at a doc that
  does not exist yet.
- `graph.json` is **write-only output** (Twenty sync + export). The spine never reads it to decide
  anything, so it cannot go stale in a way that matters. The **guard never builds the index**.

## Consequences

- **Easier:** dates stay strings; no code execution from documents; frontmatter edits are clean
  one-line diffs; template-only docs are rejected automatically; deterministic ordering aids
  reproducibility; the guard stays fast.
- **Harder:** we own the splitter and heading scanner (small, well-tested); the per-doc-type
  required-heading registry must track the schemas; remember `version` is an integer and sorting is
  code-unit.
- **Must now be true:** Topic 6 treats `events.jsonl` as the sole source of truth and `graph.json` as a
  derived projection never read back for decisions; the schemas/documents phase builds the parser,
  splitter, heading registry/scanner and id index; `.gitattributes eol=lf` lands with the repo setup.
  Phases: see `I01-PLAN`'s ADR→phase table.
- **Amended 2026-11-23:** phase numbers removed.
- **Amended 2026-11-24:** visibility → internal (every spine ADR is internal; ADR-018).
