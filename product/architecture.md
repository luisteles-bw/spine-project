---
id: ARCH
type: architecture
title: Spine architecture
stage: architecture
status: draft
version: 2
refs: [ADR-001, ADR-002, ADR-003, ADR-004, ADR-005, ADR-006, ADR-007, ADR-008, ADR-009, ADR-010, ADR-011, ADR-012, ADR-013, ADR-014, ADR-015, ADR-016, ADR-017, REQUIREMENTS, SECURITY, SPEC-ERRATA]
visibility: client
author: architect
updated: 2026-11-23
---

## Context

The spine is a deterministic SDLC CLI that drives AI-assisted development through documents, gates
and fixed lifecycles. *The spine decides, agents do the work, the human approves, Twenty displays.*

- **Actors:** the solo developer at the keyboard; five Claude Code subagents (architect, tester,
  coder, verifier, security); the client (indirect — receives delivered software and Twenty views).
- **Outside systems:** Claude Code (the harness — sandbox, permissions, PreToolUse hooks), GitHub (via
  `gh`), a self-hosted Twenty CRM, the OS keychain, the npm registry + official MCP servers, and the
  stack scaffolder (`create-next-app`). The spine **never calls an AI model** (REQ-081).

## Containers

| Container | What it is | Sandbox status |
| --- | --- | --- |
| **`spine`** | Agent + main-session CLI: `status, next, context, submit, check, pr, sync, plan apply, session, log, doctor` | Excluded (writes state) — ADR-012 |
| **`spine-admin`** | Human-only binary: `approve, reject, phase cut, repair, init, upgrade, import` | **Not** excluded — the OS boundary (ADR-012) |
| **`spine-guard`** | PreToolUse hook binary: fast allow/deny | Runs outside sandbox; `|| exit 2` (ADR-010) |
| **Pure core** | Library inside the bins: lifecycles, reducer, validation, documents, context, graph | n/a (no I/O) — ADR-001 |
| **Twenty app** | SDK-defined CRM model + REST sync target | Separate deployable (ADR-014) |
| **Claude assets** | `.claude/` settings, agents, commands, guard hook — shipped by the framework | Package templates (ADR-012) |

## Modules

| Module | Responsibility | Public interface | Depends on |
| --- | --- | --- | --- |
| `core/lifecycles` | Typed transition tables + generic reducer; named guards | `reduce(machine, state, event, ctx)` → Result | pure |
| `core/validation` | Zod-first schemas; JSON Schema export; `details[]` errors | `validate(doc)` → Result | pure (Zod) |
| `core/documents` | Frontmatter parse, heading scan, id→path index (+ ranges), ref resolution | `index(files)`, `parse(text)` | pure |
| `core/context` | Per-`(role,step)` recipe → deterministic reading list | `assemble(node, graph)` | pure |
| `core/graph` | Fold events → `graph.json` (deterministic serialize) | `project(events)` | pure |
| `adapters/fs` | Read/write, `O_EXCL` lock, append+fsync, torn-line detect | interface | `node:fs` |
| `adapters/git` | Real git via `execFile` (hooks off, isolated) | interface | `git ≥2.32` |
| `adapters/gh` | PR create + merge detection (SHA/ancestry) | interface | `gh` |
| `adapters/process` | Sandboxed check runner, secret inject + redaction | interface | `@anthropic-ai/sandbox-runtime` |
| `adapters/keychain` | `security`/`secret-tool`/0600 fallback | interface | OS |
| `adapters/twenty` | One-way REST sync (outbox, `spineId`) | interface | Twenty REST |
| `adapters/clock-id` | Injected time + `seq`/id generation | interface | OS (edge only) |
| `cli` | commander routing-only, one renderer, exit-code table | the three bins | core + adapters |

Core purity is enforced at compile time: `src/core/tsconfig.json` sets `"types": []`, and ESLint bans
`Date.now`/argument-less `new Date()`/`Math.random` under `src/core/**` (ADR-001/002).

## Data and state

All under `project/state/`, written only by the spine, write-protected from agents (ADR-012):

| File | Role | Notes |
| --- | --- | --- |
| `events.jsonl` | **Sole source of truth** | `{seq, ts, type, node, actor, payload}`; `seq` = line position; additive-only types; per-record SHA-256 (ADR-006) |
| `graph.json` | Derived, **write-only** projection | deterministic serialize, no timestamp; never read for a decision (ADR-005) |
| `active.json` | Guard's view | `{seq, role, node, attempt, scope, testFiles}`, written inside the state lock (ADR-010) |
| `crm-ids.json` | Sync **cache** | `spineId` on the record is authoritative (ADR-014) |

Records are immutable and hashed; living documents are edited in place (frontmatter via
`parseDocument`), each edit bumping `version`. Dates are strings; config is snapshotted into the
increment-creation event so `spine.yaml` edits can't change a replay (REQ-010, ADR-007).

## Key flows

1. **Next step:** `spine next --json` → `{node, role, filesToRead (sliced), template, schema}`; the main
   session dispatches to the named subagent (ADR-008).
2. **Task attempt:** tester → coder → verifier; `spine submit` validates frontmatter+headings, runs the
   **sandboxed** checks (direct tools, not `package.json` scripts), diffs against `scope.touch`, checks
   the test-file hashes recorded at "Tests ready", then commits with trailers (ADR-009/010/011).
3. **Gate:** the human runs `spine-admin approve <gate>` in a normal terminal (outside Claude Code); the
   approval is bound to the SHA of what was approved — a later edit reopens the gate (ADR-007/012).
4. **Phase PR:** `spine pr` (in `ask`) pushes the phase branch and opens the PR via `gh`; `phase_pr`
   counts only if the merged head SHA equals the review-approved SHA and is an ancestor of base
   (ADR-009).
5. **Switch-over:** migrate docs → `spine-admin import --dry-run` → verify the normalized projection
   matches `STATE.md` → apply phase-2 settings + guard hook → restart Claude Code → red-team → archive
   (ADR-016).

## Cross-cutting concerns

- **Errors:** typed `Result`, never thrown (expected failures); one renderer; exit codes `0/1/2/3`
  (`INTERNAL`→3), table-driven from `error.code` (ADR-003).
- **Logging:** human text + progress to **stderr**; `--json` emits exactly one JSON document on
  **stdout**; secrets redacted (exact value + base64/URL forms) before any output (ADR-003/011).
- **Configuration:** `spine.yaml` (write-protected); per-increment config snapshot in the event log
  (ADR-007); `context` byte budget (~100 KB, ADR-008).
- **Security:** the human-only boundary is OS-enforced via `spine-admin` + sandbox `denyWrite`; the guard
  is a fast tripwire; the real controls are the sandbox + submit-time scope-diff + record hashes. The
  **single table of human-applied settings and the phase each applies in is in `I01-PLAN`**. See
  `security.md`.
- **Testing:** four layers (unit / integration / contract / e2e), strict determinism, a quality-stage
  red-team checklist, CI under the sandbox with network denied (ADR-015).

## Decisions

| ADR | Decision |
| --- | --- |
| ADR-001 | One workspace-ready package; compile-isolated pure core; tarball `spine` + `spine-dev` |
| ADR-002 | Node 24 LTS, ESM, tsdown, ESLint+Prettier (type-aware), tsx |
| ADR-003 | commander (routing-only), uniform `--json` envelope, table-driven exit codes, separate guard bin |
| ADR-004 | Zod-first, dates as strings, discriminated unions, additive-only, committed JSON Schema |
| ADR-005 | `yaml` + tiny splitter, line-scan headings, per-command id index, derived `graph.json` |
| ADR-006 | `seq`-indexed JSONL source of truth, per-record hashes, `O_EXCL` lock, human-applied write-protection |
| ADR-007 | Typed transition tables, event-backed states, approvals bound to doc hash, config snapshot per increment |
| ADR-008 | Deterministic sliced path-list context, trust flags, plan-time budget check |
| ADR-009 | Real git via arg arrays (hook-proof), `gh` CLI, tamper-proof `phase_pr` |
| ADR-010 | One global `agent_type`-keyed guard, `active.json`, allowlist tripwire, fail-closed on exit 2 |
| ADR-011 | `sandbox-runtime` containment, direct-tool checks, keychain + layered redaction |
| ADR-012 | OS-enforced `spine-admin` boundary; consolidated hardened settings |
| ADR-013 | Package-shipped declarative profile overlays; sandboxed atomic scaffolding; pinned MCP |
| ADR-014 | Twenty 2.0 SDK model; one-way REST outbox keyed on `spineId` |
| ADR-015 | Four test layers, PATH-level `gh` stub, stateful Twenty fake, red-team, offline CI |
| ADR-016 | Genesis-event import, dry-run + re-confirmed approvals, reversible checklist |
| ADR-017 | macOS tier 1 / Linux+WSL2 tier 2; per-command preflight; `spine doctor` self-audit |

## Constraints and non-goals

- The spine **never calls an AI model** (REQ-081); every command works **offline** except `sync` and
  `pr` (REQ-084).
- **Security guarantees are claimed only on macOS (tier 1)**; Linux/WSL2 are tier 2 until red-teamed
  (ADR-017).
- **V2 / out of scope:** Twenty two-way sync and the client portal, a Gantt timeline, parallel worktrees,
  Docker sandboxes, unattended runs, native Windows (ADR-017), and the other four stack profiles.

## State directory layout

All state lives under `project/state/` and is covered by the switch-over `denyWrite` (ADR-012); only the
excluded `spine` writes it.

| File | Committed? | Role |
| --- | --- | --- |
| `events.jsonl` | committed | the sole source of truth (ADR-006) |
| `graph.json` | committed | derived, write-only projection; a diffable snapshot for sync/export (ADR-005) |
| `crm-ids.json` | committed | Twenty id cache, rebuildable from `spineId` (ADR-014) |
| `active.json` | gitignored | ephemeral guard view, rewritten inside the state lock each step (ADR-010) |
| `.lock` | gitignored | the `O_EXCL` lock (ADR-006) |

The committed files are the second audit trail beside git; the gitignored ones are ephemeral but still
`denyWrite` for agents (the glob `project/state/**` covers all five).

## Superseded wording

`I01-BRIEF` and `SPEC` are closed/approved records; where the architecture stage moved past their wording,
read them through this map (spec details in `SPEC-ERRATA`).

| Source | Original | Now |
| --- | --- | --- |
| Brief, success measure 2 | "`spine approve` fails [from an agent shell]" | **`spine-admin approve`** fails — OS-enforced, not env-detected (ADR-012) |
| Brief, suggested outline | 11 phases; P07 init, P08 Twenty, P11 delivery | the plan's **15 phases**: init **P11**, Twenty **P12**, delivery **P15** (I01-PLAN) |
| Brief, risk "env var detects agent shell" | guard blocks `spine approve` as a second layer | detection dropped; the boundary is the `spine-admin` binary + sandbox `denyWrite` (ADR-012) |
| `SPEC` | command names, per-agent hook, settings example, checks-as-scripts | see `SPEC-ERRATA` |
