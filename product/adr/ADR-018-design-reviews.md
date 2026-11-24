---
id: ADR-018
type: adr
title: Independent design reviews for the architecture stage
stage: architecture
status: accepted
superseded_by:
version: 2
refs: [REQUIREMENTS, SECURITY, ADR-010]
visibility: internal
author: architect
updated: 2026-11-24
---

## Context

The architecture stage's decisions are made by the Architect in the main conversation, and nothing in
that flow checks them independently. A reviewer with no stake, fresh context and a duty to re-verify
facts catches stale claims, bypasses and inconsistencies the Architect can't see from inside the design.

## Options

Recorded directly by the human, so no alternatives were weighed here. The realistic alternative — no
independent review (the status quo this replaces) — was rejected implicitly by the decision.

## Decision

One subagent, **`design-reviewer`** (Opus, fresh context; read-only tools plus WebSearch/WebFetch; the
only file it writes is its review file), runs in three modes:

1. **topic** — a **blind** review of a topic's questions *before* the human decides; it must not read the
   Architect's recommendation (`topics/Tnn.architect.md`).
2. **adr** — the ADR's fidelity to the human's recorded decision, and its impact on every other document.
3. **stage** — the whole stage before `stage_exit`: bypass attempts, fact re-verification, consistency,
   plan vs the brief's goals.

- **No review runs in the Architect's own context.** The Architect writes documents, fills each
  finding's **Response**, and asks the human; the human **decides** (the **Decision** column).
- Each review is a **record** (`type: review`), written once.
- **By tier:** **S** none (no architecture stage); **M** topic + stage; **L** and **the spine itself** all
  three. A **CR that changes an ADR** triggers an `adr` review.

## Consequences

- The spine **enforces this at `stage_exit`**: the gate refuses unless the required reviews exist and
  every finding has a Response (REQ-090, by tier).
- Once the guard exists, its read scope for `design-reviewer` in **topic** mode **excludes**
  `topics/Tnn.architect.md`, so the blind review stays blind (REQ-091).
- The reviewer's brief is a **write-protected agent file** once installed into `.claude/`
  (`design-reviewer.md`) plus three write-protected `review-*` commands — covered by SEC-014 / SEC-019;
  the `code/claude/` source is framework-controlled — so an agent can't weaken the review.
- **Easier:** independent fact-checking and bypass-hunting; a clean record of what was reviewed and
  decided. **Harder:** more steps per topic (a questions file + a blind review before deciding) and an
  extra gate precondition; the Architect must keep the recommendation out of the questions file.
- Applies from now. The reviewer did not exist while I01's architecture ran, so I01's `stage_exit`
  readiness now depends on running these reviews (not done in this task).

## Impact

This decision changes:
- `requirements.md` — REQ-090 (the `stage_exit` review precondition, by tier; CR→adr-review) and REQ-091
  (the guard's blind read scope).
- `plan.md` — REQ-090 → P06, REQ-091 → P09; coverage rows; the "Bootstrap (now)" settings row.
- `architecture.md` — the `design-reviewer` as a sixth (architecture-stage-only) agent and the reviews
  precondition on `stage_exit`.
- `code/claude/agents/architect.md` and `code/claude/commands/architecture.md` — the review steps in the
  architecture-session flow.
- New write-protected assets installed into `.claude/` at init (SEC-014): `design-reviewer.md` and the
  three `review-*` commands.
- ADR-013/016 → internal, and (by the "every spine ADR is internal" rule) all remaining ADRs.

## Transition (I01)

This decision postdates I01's architecture work, so for **I01 only**:
- **Topic reviews are waived for T01–T17** — those decisions predate ADR-018, and each topic was
  reviewed externally before the human decided.
- **ADR reviews run for ADR-018 and the security-mechanism ADRs 006, 009, 010, 011 and 012**; the other
  ADRs are covered by the stage review.
- **The stage review runs in full.**
- I01's `stage_exit` is **review-complete** when those reviews have run, every finding has a Response,
  and every decision is recorded.
