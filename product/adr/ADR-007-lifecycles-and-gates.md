---
id: ADR-007
type: adr
title: Lifecycles & gates — typed transition tables, event-backed states, config snapshot per increment
stage: architecture
status: accepted
superseded_by:
version: 3
refs: [REQ-011, REQ-010, REQ-082, REQ-014, SEC-002]
visibility: internal
author: architect
updated: 2026-11-24
---

## Context

Five fixed lifecycles (REQ-011) with every transition tested, including refusals (REQ-082). They must
replay deterministically (REQ-010) even as `spine.yaml` evolves, and gates/limits must be configurable
without becoming a way for an agent to weaken the process (SEC-002). The retry ladder lives here too
(REQ-014).

## Decision

### Representation — typed tables + one generic pure reducer
- Each lifecycle is a declarative table: `state × event → nextState`, each transition optionally tagged
  with a `gate` and a named **guard** — a pure function referenced **by name**, never an inline
  closure, so the table stays printable.
- One generic pure reducer applies a table: `reduce(machine, state, event, ctx)` returns
  `{ ok, next }` or `{ refused, from, allowed[], reason }`. Refusals are typed, never thrown, and name
  `from` and the `allowed[]` moves (REQ-011).
- **Every state change has an event.** The reducer never infers a change with no event; when a limit
  trips, the command appends an explicit event (e.g. `task_blocked`).
- Tests enumerate the **full `state × event` product** per machine (every refusal, not only the listed
  moves) — REQ-082.
- The docs' lifecycle diagrams are **generated from the tables**, so they cannot drift.

### Gates — tags in code, config scopes (never disables)
- The tables tag which gate guards which transition (structural truth in code). `spine.yaml` only
  **scopes** gates by track and profile (e.g. `schema_migration` exists only for database profiles);
  it can **never disable** a gate.
- `spine.yaml` gets the **same write protection as the event log** (ADR-006), so an agent cannot weaken
  the process by editing one line.
- An approval is **bound to the SHA-256 of what was approved** (plan, CR, record). If that document
  changes afterwards, the approval no longer counts and the **gate reopens**.
- `phase_pr` is satisfied by **GitHub-merge detection**: its event records the PR number, base branch
  and merge SHA; a PR closed without merging never satisfies it. All other gates go through
  `spine-admin approve`.

### Increment stages — fixed order in code, track omits only
- The six stages and their order live in **code**. A track may **omit** stages but never reorder or add
  them; the spine validates this.
- At increment creation, the **track, active gate set and limits are copied into the creation event**;
  the reducer reads them **from the event**, not from the current `spine.yaml`. Editing `spine.yaml`
  therefore cannot change how an existing log replays (protects REQ-010).
- Config changes apply to **new increments only**; changing a running increment's track goes through a
  **CR**.
- Test: replay a log, mutate `spine.yaml`, replay again → identical graph.

## Consequences

- **Easier:** exhaustive, enumerable transition tests; printable tables and generated diagrams; replay
  stability guaranteed by snapshotting config into events; approvals that auto-reopen when their
  subject changes (strong gate integrity).
- **Harder:** guards must be named pure functions and the per-machine tables maintained; config must be
  snapshotted at increment creation and the reducer must never read live `spine.yaml`; `spine.yaml`
  must be write-protected like state.
- **Must now be true:** the tables, reducer, guards, the full-product transition tests and the
  replay-stability test are built in the core phase; the increment-creation event carries the
  track/gates/limits snapshot; `phase_pr` detection (PR #, base, merge SHA) is wired in the git/PR work;
  `spine.yaml` joins the ADR-006 write-protection set. Phases: see `I01-PLAN`'s ADR→phase table.
- **Amended 2026-11-23:** `spine approve` → `spine-admin approve`; phase numbers removed.
- **Amended 2026-11-24:** visibility → internal (every spine ADR is internal; ADR-018).
