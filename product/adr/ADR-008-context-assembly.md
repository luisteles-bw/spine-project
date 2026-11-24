---
id: ADR-008
type: adr
title: Context assembly — deterministic sliced path list, trust flags, plan-time budget check
stage: architecture
status: accepted
superseded_by:
version: 3
refs: [REQ-024, REQ-031, SEC-008, REQ-033]
visibility: internal
author: architect
updated: 2026-11-24
---

## Context

`spine context <id>` assembles a node's reading list deterministically — same state, same list —
including `refs`, `parent` and the latest verify record (REQ-024). `next --json` names the same "files
to read" (REQ-031), so both share one recipe. Client-sourced text must be labelled untrusted
(SEC-008), and an oversized context is a signal the task scope is too broad (feeds plan apply,
REQ-033).

## Decision

**Output — a deterministic path list (not a content bundle).**

- `spine context <id>` returns an ordered list of entries; each entry carries `path`, `reason`
  (`self | parent | ref | latest-verify | product | tests | …`), `bytes`, and — for ids defined inside
  a larger doc — a `range`.
- The recipe is a declarative table keyed by `(role, step)`, computed in pure core from the graph +
  id index; `next --json`'s "files to read" uses the same recipe.
- **Slices, not whole files.** Ids defined as headings inside a larger doc (`### REQ-031 …`, SEC, AC)
  are indexed with their **line range** — this **extends the ADR-005 index** — and the entry points at
  that slice, so the role reads it with `Read` offset/limit instead of all 84 requirements.
- **Trust flag.** Each entry carries `trusted: false` when the doc came from a client (tickets,
  feedback), so the role treats it as data (SEC-008, `CLAUDE.md`).
- **Latest verify** means the highest attempt number **in the event log**, never file mtime.
- The list is **what to read first**, not a read-scope; read permission stays with the guard (Topic 10).
- The **attempt-start event records the list with per-entry content hashes**, so a failed attempt
  shows exactly what it was given.

**Size limits — soft warning, plus a plan-time check.**

- Warn when the list exceeds a configurable **byte** budget in `spine.yaml`; never block at run time.
  Start around **100 KB (~25k tokens)** and tune from real tasks.
- The budget counts **slices, not whole files**.
- Warnings are returned **inside `data`** (the ADR-003 envelope has no warnings field); an optional
  `chars/4` token estimate may be shown for convenience, but the budget is bytes.
- **Plan time too:** `plan apply` computes each task's context size and lists over-budget tasks in the
  **plan gate summary**, so they can be split before any work starts.

## Consequences

- **Easier:** minimal, deterministic context; roles read slices not whole files; untrusted content is
  labelled; a failed attempt's exact inputs are reconstructable from its start event; oversized scopes
  are caught at the plan gate.
- **Harder:** the id index must record line ranges for in-doc ids (extends ADR-005); the recipe table
  must be maintained per `(role, step)`; the renderer must honour a `data.warnings` convention.
- **Must now be true:** ADR-005's index gains line ranges (schemas/documents phase); the recipe table,
  `spine context` and the attempt-start context snapshot are built in the CLI phases; `plan apply`
  includes the per-task context-size check; `spine.yaml` gains a `context` byte budget (~100 KB). Phases:
  see `I01-PLAN`'s ADR→phase table.
- **Amended 2026-11-23:** phase numbers removed.
- **Amended 2026-11-24:** visibility → internal (every spine ADR is internal; ADR-018).
