---
id: ADR-006
type: adr
title: Event log & state — seq-indexed JSONL source of truth, derived graph.json, per-record hashes, O_EXCL lock
stage: architecture
status: accepted
superseded_by:
version: 1
refs: [REQ-010, SEC-002, SEC-012, SEC-003]
visibility: client
author: architect
updated: 2026-11-22
---

## Context

`events.jsonl` is the sole source of truth (ADR-005); `graph.json` is a derived, write-only
projection that must rebuild **byte-identically** (REQ-010). This is the component that must never be
wrong: identity, ordering, integrity (SEC-012), single-writer safety and crash recovery all live
here. The integrity model assumes "only the spine writes state" (SEC-002) — which the harness does
**not** enforce today.

## Decision

### Event shape & identity
- One JSON object per line: `{ seq, ts, type, node, actor, payload }`.
- `seq` is a monotonic integer that **equals the line's position** in the file — the event's identity
  and order. On read, `seq ≠ position`, or any gap or duplicate, is a **hard stop** (exit 3), the same
  as a corrupt interior line.
- `type` is **additive-only** (like ADR-004): an existing type never changes meaning; a new meaning
  gets a new type, so the reducer can replay any old log.
- `ts` comes from the **injected clock**; `actor` is set by the spine from agent-shell detection
  (Topic 12), **never from a flag**. Gate decisions are events carrying who / when / note (SEC-003).

### Derived graph.json
- Pure reducer `(events) → graph`; deterministic serialization (sorted keys, 2-space indent, trailing
  `\n`); **no generated-at timestamp** (it would break REQ-010). Write-only; never read back for a
  decision.

### Integrity
- Each submitted **record** is hashed as **raw bytes at submit** (SHA-256) and the hash is stored in
  its event (SEC-012). Records are **never edited afterwards, not even by the spine**; their later
  status lives only in the event log. **Every gate re-checks all record hashes.**
- This clarifies ADR-005: in-place frontmatter edits apply to **living** documents only; **records are
  write-once**.
- Log integrity otherwise rests on "only the spine writes state" + the `project/` git history (a commit
  per transition, a second audit trail). No event hash chain in the MVP (optional later hardening).

### Enforcing "only the spine writes state" (SEC-002) — human-applied settings
The sandbox auto-allows sandboxed Bash writes today, so these `.claude/settings.json` / sandbox
changes are applied **by the human** (agents cannot edit `.claude/`), at the **switch-over**, once the
spine owns `STATE.md` and the event log:
1. `sandbox.filesystem.denyWrite` plus `Edit`/`Write` deny rules for the event-log directory,
   `STATE.md` (once generated) and `project/.git`, so only the spine commits to `project/`.
2. `excludedCommands: ["spine *"]`, so the spine is the one process that may write there.
3. Human-only subcommands also get Bash deny rules (details in Topic 12).
4. `allowUnsandboxedCommands: false`, so a blocked write can't be retried unsandboxed through a
   reflex-approved prompt.
5. The spine runs **outside** the sandbox and therefore never spawns project code; tests and builds
   stay sandboxed (Topic 11).

Verify the exact setting keys against the current Claude Code docs when written — the brief flags that
these formats change.

### Single-writer locking
- Hand-rolled **`O_EXCL`** lockfile (pid + timestamp) in the fs adapter.
- Hold the lock **only** around `read → validate → append → write graph → commit`; never while anything
  slow runs; **re-read the last `seq` under the lock** before appending.
- A lock is **stale when its pid is dead on this host** (`process.kill(pid, 0)`); the timestamp is kept
  **only for the error message** — a time-based expiry could steal a live lock.
- `proper-lockfile` is rejected: it targets long-running holders that refresh mtime on a timer, which
  we don't have.

### Recovery
- Validate every line on read. A **torn final line** (crash mid-append) is repaired by a **human-only**
  command that truncates it after confirmation. A corrupt / gap / duplicate **interior** line is a hard
  stop (exit 3); fix it from git history.

### Single-machine assumption
- One machine writes `project/`. If two ever do, colliding `seq`s surface as a **git conflict** — the
  failure we want.

## Consequences

- **Easier:** trivial ordering and identity; deterministic rebuild; well-defined crash recovery;
  minimal, correct locking for a short critical section; tamper-evidence from per-record hashes + git.
- **Harder:** we own the stale-pid lock logic and the torn-line repair; the "only spine writes"
  guarantee depends on human-applied settings that must be verified against current Claude Code docs;
  write-once records mean all mutable status lives in events — the reducer, not the file, is
  authoritative.
- **Must now be true:** clock and ids are injected ports (ADR-001); Topic 11 keeps tests/builds
  sandboxed while the spine runs outside; Topic 12 consolidates settings.json + agent-shell detection;
  P03 builds the log, reducer, lock and recovery as pure core + a thin fs adapter with heavy tests
  (REQ-010 and every transition); the human applies the SEC-002 hardening at switch-over.
