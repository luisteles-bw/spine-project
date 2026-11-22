---
id: ADR-003
type: adr
title: CLI contract — commander in routing-only mode, uniform JSON envelope, table-driven exit codes
stage: architecture
status: accepted
superseded_by:
version: 1
refs: [REQ-020, REQ-031, REQ-051]
visibility: client
author: architect
updated: 2026-11-22
---

## Context

Nineteen commands, parsed by a thin CLI that calls the core and prints (`conventions.md`). Agents
parse `--json`, so output must be uniform and machine-actionable (REQ-020 field-level errors; REQ-031
`next --json` validates against its schema). `conventions.md` fixes typed results (never thrown),
`--json` on every command and exit codes 0/1/2/3. The guard runs on **every** agent tool call
(REQ-051), so it must start without loading the whole command tree.

## Options

| Choice | Options | Decision |
| --- | --- | --- |
| Parser | commander · citty (0.x) · `util.parseArgs` | **commander**, pinned v15 (ESM-only) |
| `--json` shape | uniform envelope · bare-on-success | **uniform envelope** |

## Decision

**Parser — commander (pin v15, ESM-only; fine on Node 24).** citty is still 0.x, and sharing an
ecosystem with tsdown gains nothing because tsdown bundles any parser.

- Call `.exitOverride()` and `.configureOutput()` so commander **never prints or exits on its own**;
  usage errors are routed through our renderer as **exit 2**.
- Commander only determines **which command and which flags** were given. It does **not** validate
  values — the **core schemas** validate values (`--billing hourly`, ids, …), so every validation
  error shares the same `details` shape and is testable without the CLI.

**Output contract — uniform envelope.**

- Envelope: `{ ok, command, data?, error? }` with `error: { code, message, details: [{ path, message }] }`.
- With `--json`, **stdout carries exactly one JSON document for every outcome** — success, refused,
  invalid, environment, and unexpected crashes (`error.code: INTERNAL`). Human logs and progress go
  to **stderr**, so stdout stays a single clean document.
- `error.code` comes from **one fixed list in core**. The numeric exit code is **looked up from that
  code in one table**, never set separately: `ok→0, refused→1, invalid→2, env→3, INTERNAL→3`.
- The CLI has **one** renderer and **one** exit mapper; no command handler prints or sets a code.

**Guard.** The guard ships as its **own tsdown entry and bin**, so invoking it never loads the
19-command tree; the PreToolUse hook calls that bin directly (guard internals finalised in Topic 10).

**Testing.** A contract test runs **each** command with `--json` and validates the output against the
envelope schema.

## Consequences

- **Easier:** agents parse one shape; validation errors are uniform and testable in core without
  spawning the CLI; the guard starts fast; exit codes cannot drift because they are table-driven.
- **Harder:** commander must be kept in pure routing mode (no built-in validators or coercion); the
  core `error.code` list, the code→exit table and the envelope schema must be maintained; bucketing
  `INTERNAL` into exit 3 widens code 3 to "environment **or** internal error" — update
  `conventions.md` at session close.
- **Must now be true:** Topic 4 picks the value-schema library that produces the `details` shape;
  P01/P04 build the renderer, exit table, envelope schema and the separate guard bin; the `--json`
  contract test is part of the CLI phase.
