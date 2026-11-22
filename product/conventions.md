---
id: CONVENTIONS
type: conventions
title: Spine coding conventions
stage: discovery
status: approved
version: 1
refs: [SPEC]
visibility: internal
author: architect
updated: 2026-11-22
---

Defaults for the spine's own code. An ADR can change any of them; when it does, update this file
and bump `version`.

## Language and runtime
- TypeScript in strict mode, ES modules, the current Node.js LTS.
- pnpm for packages. No dependency without the `new_dependency` gate.

## Structure
- **Core is pure.** Lifecycles, transitions, graph building, validation and context assembly take
  data in and return data out. No file system, no git, no clock, no environment access inside the
  core; pass those in.
- **Adapters at the edge.** File system, git, process running, keychain and Twenty each live behind
  a small interface, so the core is tested without them.
- **The CLI is thin.** It parses arguments, calls the core and adapters, and prints. No business
  rules in command handlers.

## Errors and output
- Expected failures (invalid transition, invalid document) are returned as typed results with a
  message an agent can act on, never thrown.
- Every command supports `--json` for machine output; human output is short and plain.
- Exit codes: 0 success, 1 refused (rules), 2 invalid input, 3 environment problem.

## Tests
- Vitest. Unit tests sit next to the code as `*.test.ts`; integration tests in `tests/` use temporary
  directories and real git.
- Name each test after the criterion it proves: `AC-1: …`.
- Every lifecycle transition, allowed and refused, has a test.

## Security habits
- Run processes with argument arrays, never shell strings.
- Validate ids and slugs with strict patterns before they touch a path or a command.
- Never log a value that came from the keychain or an env file.

## Style
- Formatting and linting are enforced by the tools chosen in the architecture stage; don't argue
  with the formatter.
- Small files with one responsibility. Names say what something is, not how it works.
- Comments explain why, not what.

## Commits
- Conventional Commits: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `ci`.
- Trailers on every task commit: `Task: P03-T02` and `Attempt: 2`.
