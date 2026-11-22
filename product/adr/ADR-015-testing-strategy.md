---
id: ADR-015
type: adr
title: Testing strategy — four layers, PATH-level gh stub, stateful Twenty fake, strict determinism
stage: architecture
status: accepted
superseded_by:
version: 1
refs: [REQ-082, REQ-010, REQ-071, REQ-083]
visibility: client
author: architect
updated: 2026-11-22
---

## Context

Tests must prove the core is deterministic (REQ-010), every transition is covered including refusals
(REQ-082), sync makes no duplicates (REQ-071), and everything runs on macOS + Linux (REQ-083) without
flaky external dependencies. Earlier ADRs fix much of this; this ADR fixes the external-boundary
strategy and the determinism controls.

## Decision

### Layers (the standard)
- **Unit** (`*.test.ts` beside code): pure core with injected clock/ids; the full `state × event`
  transition product (REQ-082); replay-stability (ADR-007).
- **Integration** (`tests/`): temp dirs + **real git**; external processes faked.
- **Contract**: the `--json` envelope per command (ADR-003); the Ajv schema (ADR-004).
- **E2E**: one fixture driven `init` → merged phase PR with only spine commands; golden event-log +
  `graph.json`.

### E2E / git boundary
- **Fake `gh` at the process boundary**, not in the TS adapter: a tiny `gh` script first on `PATH`
  records its argv and returns JSON **recorded from a real `gh pr view`** — so the test covers both the
  arguments we build and our parsing of real output. The remote is a **local bare repo**.
- The e2e asserts the **ADR-009 refusals**: after a squash merge, and after a post-review push,
  `phase_pr` **stays unsatisfied**.
- **Git isolation:** `GIT_CONFIG_GLOBAL=/dev/null`, `GIT_CONFIG_NOSYSTEM=1`, and fixed author/committer
  name, email and date — so global config (signing, default branch, hooks) can't leak in and commit
  SHAs are stable for the golden files.
- **Events store only workspace-relative paths**, never temp-dir paths.
- **Guard tests** feed recorded PreToolUse payloads to the **real binary**, including a **simulated
  crash**, proving `|| exit 2` blocks.

### Twenty tests
- A **small stateful fake** of the REST endpoints we call (response shapes from recorded fixtures) —
  static fixtures can't prove REQ-071. Cover **sync twice**, **sync after deleting `crm-ids.json`**, and
  **sync after a record was deleted in Twenty** — all produce no duplicates.
- Fixtures are recorded from a **throwaway local Twenty with fake data**, never the real CRM (they're
  committed). Each fixture stores the **Twenty version** it came from; a mismatch with the pinned
  version (ADR-014) fails the test, forcing a re-record.
- The real-Twenty check is a **manual script** (`pnpm test:twenty`, local Docker, **not CI**), run on
  every Twenty bump and before release.

### CI
- macOS + Linux, Node 24 (REQ-083); no Docker / Twenty / GitHub network in CI — fast, offline,
  deterministic.
- The suite runs **under the sandbox runtime with network denied**, so REQ-084 (offline except
  `sync`/`pr`) is **proven, not assumed**.

### Security & property verification
- **Red-team checklist (quality stage, before each release tarball).** The automated layers don't
  exercise Claude Code's sandbox, permissions or the guard hook, yet ADR-006/009/010/012 depend on them.
  A short **scripted agent session** attempts the known bypasses — append to `events.jsonl`;
  `env -u CLAUDECODE spine-admin approve`; `git -C code reset`; edit `code/CLAUDE.md`; read `.env` via
  `node -e`; write a git hook; symlink outside the scope. **Each attempt must fail**, and the results are
  saved as a **record**.
- **Optional: `fast-check` property tests** for the reducer — random event sequences must replay
  byte-identically and keep the invariants (a `new_dependency` gate when added).

## Consequences

- **Easier:** a deterministic golden e2e that still exercises real `gh` argv + output parsing; the
  `phase_pr` refusals are regression-tested; REQ-071 is proven against a stateful fake; CI is fast and
  offline; a Twenty bump can't silently drift fixtures.
- **Harder:** maintain the on-PATH `gh` stub + recorded JSON, the stateful Twenty fake, and the
  fixture-version guard; keep events path-relative and git fully isolated.
- **Must now be true:** every phase's tests follow the four layers; events carry workspace-relative paths
  (P03); the e2e harness (bare remote, PATH `gh` stub, git-isolation env) lands with the build loop
  (P06/P07); the Twenty stateful fake + `pnpm test:twenty` land in P08; the CI matrix is
  macOS + Linux / Node 24 and runs under the sandbox with network denied (P01); the quality stage (P10)
  runs the red-team bypass checklist and saves the record; `fast-check` is an optional reducer property
  test (gate).
