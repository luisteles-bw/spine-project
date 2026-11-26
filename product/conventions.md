---
id: CONVENTIONS
type: conventions
title: Spine coding conventions
stage: discovery
status: approved
version: 3
refs: [SPEC]
visibility: internal
author: architect
updated: 2026-11-26
---

Defaults for the spine's own code. An ADR can change any of them; when it does, update this file
and bump `version`.

## Language and runtime
- TypeScript in strict mode (plus `erasableSyntaxOnly` and `verbatimModuleSyntax`), ES modules,
  **Node 24 LTS** (ADR-002).
- **tsdown** bundles the CLI; **tsx** runs it in development; **Vitest** for tests.
- pnpm (≥ 10.26) for packages. No dependency without the `new_dependency` gate.

## Structure
- **Core is pure.** Lifecycles, transitions, graph building, validation and context assembly take
  data in and return data out. No file system, no git, no clock, no environment access inside the
  core; pass those in. Enforced at compile time: `src/core/tsconfig.json` sets `"types": []`, and
  ESLint bans `Date.now`, argument-less `new Date()` and `Math.random` under `src/core/**` (ADR-001).
- **Adapters at the edge.** File system, git, process running, keychain and Twenty each live behind
  a small interface, so the core is tested without them.
- **The CLI is thin.** It parses arguments, calls the core and adapters, and prints. No business
  rules in command handlers.

## Errors and output
- Expected failures (invalid transition, invalid document) are returned as typed results with a
  message an agent can act on, never thrown.
- Every command supports `--json`: it emits **exactly one JSON document on stdout** for every outcome
  (the `{ ok, command, data?, error? }` envelope); human text, logs and progress go to **stderr**.
  Secrets are redacted from all output (ADR-003, ADR-011).
- Exit codes come from one table keyed on `error.code`: 0 success, 1 refused (rules), 2 invalid input,
  3 environment **or** internal error (`INTERNAL`). No handler sets a code directly (ADR-003).

## Tests
- Vitest. Unit tests sit next to the code as `*.test.ts`; integration tests in `tests/` use temporary
  directories and real git.
- Name each test after the criterion it proves: `AC-1: …`.
- Every lifecycle transition, allowed and refused, has a test.
- The spine's own `check` runs tools **directly** (`vitest run`, `eslint .`, `tsc --noEmit`), never
  `package.json` scripts, which an agent could weaken (ADR-011).

## Security habits
- Run processes with argument arrays, never shell strings.
- Validate ids and slugs with strict patterns before they touch a path or a command.
- Never log a value that came from the keychain or an env file.

## Style
- Formatting and linting are enforced by **Prettier + ESLint** (type-aware; `no-floating-promises`);
  don't argue with the formatter (ADR-002).
- Small files with one responsibility. Names say what something is, not how it works.
- Comments explain why, not what.

## Commits
- Conventional Commits: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `ci`.
- Trailers on every task commit: `Task: P03-T02` and `Attempt: 2` (also `Ticket`/`CR` where relevant),
  set via git's `--trailer`. `project/` transition commits carry `Spine-Seq: <n>` (ADR-009).

## Corrections vs change requests (after a gate)
- A **correction** edits an already-approved document to fix a **fact, key path, shape or wording
  without changing any decision**. It gets an amend line in the document and a `STATE.md` log line, and
  **reopens no gate**. All corrections made during a phase are re-checked together by `/review-adr` at
  that phase's review (ADR-018).
- An edit that **changes a decision** is **not** a correction: raise a **CR** (internal or client),
  which triggers its own `adr` review (ADR-018).
