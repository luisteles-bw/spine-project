---
id: ADR-016
type: adr
title: Switch-over — genesis-event import, dry-run + re-confirmed approvals, reversible checklist
stage: architecture
status: accepted
superseded_by:
version: 2
refs: [REQ-035, REQ-050, SEC-002]
visibility: client
author: architect
updated: 2026-11-23
---

## Context

Once `status`, `next`, `submit` and `approve` work, the spine imports the hand-maintained `STATE.md`
into the event log so `spine status` matches it (REQ-035), rewires the bootstrap commands and agents to
the real spine (REQ-050), and turns on the phased state/git write-protection (ADR-012, SEC-002). It must
stay reversible until it is proven.

## Decision

### Import — a genesis event sequence (dry-run first)
- Emit the discrete events `STATE.md` justifies — I01 created (with its track/gates/limits snapshot,
  ADR-007), each `stage_exit`, each "Gates passed" row — marked `source: bootstrap-import` with the
  original dates and actors. Honours "every state change has an event" (ADR-007).
- **Order:** run the **ADR-004 migration pass first** (every bootstrap doc validates, every ref
  resolves), then import.
- **`spine-admin import --dry-run`** prints the events and the status diff before anything is applied.
- **Re-confirm imported approvals:** for each hand-recorded approval, the import shows the document's
  **current hash** and asks the human to confirm — binding each approval to what exists today (ADR-007),
  not trusting `STATE.md` blindly.
- The import **hashes every existing record**, so record immutability (ADR-006) starts at switch-over.
- **"Matches `STATE.md`"** compares a **normalized projection** (increment, stage, phase/task statuses,
  open gates, gates passed) — not the text, since "Next action" is prose.

### Cutover — a checklist with a way back
1. **Tag both repos** pre-switch-over (human; agents can't tag).
2. Install the release tarball globally (ADR-001).
3. Migrate the docs (ADR-004).
4. Import and verify (above).
5. Apply the **phase-2 settings + the guard hook** — only now, since `spine-guard` is installed
   (ADR-012).
6. **Restart Claude Code** so the new settings and hooks load.
7. Run the **red-team checklist** (ADR-015).
8. **Archive.**
- **Rollback** = restore the tags + the previous settings; keep that path **until the first phase
  completes under spine**.

### Commands, agents & STATE.md
- Archive the bootstrap file as **`STATE.bootstrap.md`**; `STATE.md` thereafter means only the
  generated, write-protected view.
- **`/approve` and `/reject` become stubs** that say "approve in a terminal: `spine-admin approve
  <gate>`" — not removed, so an agent asked to approve can't improvise by editing files.
- `/status` · `/next` · `/architecture` call the real spine; `CLAUDE.md` and the agent files come from
  the **package templates via `spine-admin upgrade`** (ADR-012); a **check fails if any of them still
  tells agents to edit `STATE.md`** (REQ-050).

## Consequences

- **Easier:** a reversible, auditable switch with a dry-run and a verified projection match; approvals
  re-bound to current content; immutability and hardening begin at one clean point.
- **Harder:** the genesis-import generator + normalized-projection comparator must be built and tested;
  the ordered checklist (migrate → import → settings → restart → red-team → archive) must be followed;
  a lint check must scan agent docs for stale `STATE.md` instructions.
- **Must now be true:** this is the **switch-over task** in the plan (after `status`/`next`/`submit`/
  `approve` work); `spine-admin import --dry-run` + the projection comparator ship with it; the
  `/approve`·`/reject` stubs, `STATE.bootstrap.md` archival and the "no STATE.md in agent docs" check
  land at switch-over; rollback stays available until the first post-switch phase merges. Phases: see
  `I01-PLAN`'s ADR→phase table.
- **Amended 2026-11-23:** phase number removed.
