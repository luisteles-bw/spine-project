---
id: ADR-014
type: adr
title: Twenty app & sync — SDK-defined model, one-way REST outbox keyed on spineId
stage: architecture
status: accepted
superseded_by:
version: 3
refs: [REQ-070, REQ-071, SEC-013, SEC-008]
visibility: internal
author: architect
updated: 2026-11-24
---

## Context

A Twenty app defines the custom objects, fields and views from `taxonomy.json` (REQ-070); `spine sync`
upserts **one way** by spine id, idempotently, with no duplicates (REQ-071); only whitelisted fields
and `visibility`-allowed docs are sent (SEC-013); anything read back from Twenty is untrusted (SEC-008).
Twenty is built late (its own phase) and only reads what the spine produces.

## Decision

### Data model — the Twenty 2.0 app SDK
- Use the **Twenty 2.0 app SDK** (April 2026) as the main extension path: custom objects, fields on
  standard objects (Opportunity, Company), relations and views with **stable identifiers**, where **each
  sync enforces the declared state** (REQ-070). The brief's "SDK is young" risk predates 2.0; a
  hand-written metadata applier would just rebuild what the SDK now gives.
- **Conditions:** pin the **Twenty Docker image and `twenty-sdk` versions together** (upgrade
  deliberately); **generate the SDK definitions from `taxonomy.json`** (one source); **the Twenty phase opens with a
  half-day spike** — one object, one field on Opportunity, one relation, one view, synced twice to a
  fresh local Twenty — and falls back to the **metadata API only if the spike fails**.
- Model changes are **additive-only** (like ADR-004); removing a field may drop its data on the next
  sync, so a removal needs a **database backup + a CR**.

### Sync — one-way REST, outbox on the event log
- **REST** (Twenty's auto-generated per-object CRUD).
- Every synced record carries its spine id in a **unique `spineId` field**. `crm-ids.json` is only a
  **cache**: on a miss or a 404, sync looks the record up by `spineId` before creating it — so a lost
  cache, a restored Twenty backup or a record deleted in the UI never produces duplicates (REQ-071).
- **Ownership split:** the spine **owns and overwrites** the objects it creates (Project, Increment,
  Phase, Dev Task, Change Request, Ticket, Billing Item, Project Doc). It **never writes** Opportunity,
  Company or Person — the human edits those in Twenty; the spine only **links** to them.
- **Outbox on the event log:** sync stores the **last synced `seq`** and replays from there, so a failed
  sync never blocks or rolls back a transition — it catches up next time. Triggered `on_transition`
  (per `spine.yaml`) plus a manual `spine sync`.
- Document bodies go in as **Markdown** to the rich-text field (tables/code may render imperfectly,
  Mermaid as plain text). Only **whitelisted fields and `visibility`-allowed docs** are sent (SEC-013). A
  small **retry/backoff + throttle** client handles rate limits.

### Reads & secrets
- Anything **read** from Twenty (e.g. the opportunity name at init) enters the workspace as
  **`trusted: false`** (SEC-008). The **Twenty API key lives in the keychain** (ADR-011), never in
  `spine.yaml`.

## Consequences

- **Easier:** the SDK enforces declared state (no drift); `spineId` + lookup-before-create makes sync
  robust to cache loss and manual edits; the outbox decouples sync from transitions; the ownership split
  avoids clobbering human-curated CRM data.
- **Harder:** Twenty image + SDK versions must move together; the Twenty-phase spike is a go/no-go on the
  SDK; additive-only model with CR-gated removals; Markdown rich-text rendering needs checking.
- **Must now be true:** `taxonomy.json` generates the SDK definitions; the Twenty phase runs the spike
  first, then builds the app (objects/fields/views/relations), a `spineId` on every owned object, the REST
  sync client (outbox by `seq`, lookup-before-create, throttle/backoff) and `crm-ids.json` as cache;
  Twenty reads are labelled untrusted; the Twenty API key is a keychain entry; a field removal needs a
  backup + CR. Phases: see `I01-PLAN`'s ADR→phase table.
- **Amended 2026-11-23:** phase numbers removed (Twenty phase is P12 in the plan).
- **Amended 2026-11-24:** visibility → internal (every spine ADR is internal; ADR-018).
