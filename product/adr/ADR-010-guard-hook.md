---
id: ADR-010
type: adr
title: Guard hook — one global agent_type-keyed hook, active.json, allowlist tripwire, fail-closed on exit 2
stage: architecture
status: accepted
superseded_by:
version: 1
refs: [REQ-051, REQ-052, SEC-004, SEC-001]
visibility: client
author: architect
updated: 2026-11-22
---

## Context

The guard is a PreToolUse hook on **every** tool call (REQ-051, REQ-052). It must be constant-time —
no index build, no `graph.json` read (ADR-005) — and ships as its own bin (ADR-003). Hooks run
**outside the sandbox with full user access**, and Claude Code blocks a tool call **only** on hook exit
code 2. It enforces per-role write scopes and the task's `scope.touch`/`forbid`, never letting the
Coder edit the current attempt's tests (SEC-004), and blocks gate commands and secret reads (SEC-001,
REQ-052).

## Decision

### Role & scope source
- **One global PreToolUse hook.** The role is the hook input's **`agent_type`** (hooks fire for subagent
  calls too). No `agent_type` = the **main session** (its own fixed policy). **Unknown agent types are
  read-only.** (This replaces the spec's per-agent `spine guard --role coder`.)
- Spine writes a tiny **`active.json`** — `{ seq, role, node, attempt, scope:{touch,forbid}, testFiles }`
  — **inside the same ADR-006 lock as the event append**, carrying the event `seq`, so state and
  active-context can't drift. The guard reads only this (O(1)).
- **Every tool is matched;** a tool the guard doesn't recognise is **denied for scoped roles** (a new
  Claude Code tool can't slip past). Scope matching uses **realpath**, so a symlink inside the scope
  can't point outside it.

### Bash inspection — per-role allowlist of shapes (a tripwire)
- The tokenizer feeds a **per-role allowlist of command shapes**, not a denylist. Scoped roles (tester,
  coder, verifier) may run their **check commands + read-only tools**, nothing else.
- **Denied:** `$(…)`, backticks, `eval`, `-c`/`-e` interpreters, any redirection to a file, and anything
  the tokenizer can't parse. File writes go **only** through Edit/Write (where scope is checked);
  otherwise `echo > file` would bypass `scope.touch`.
- This layer is a **tripwire, not a wall.** The real controls are the **sandbox** and **spine's submit
  checks**: the diff against scope (ADR-009) and the **test-file hashes recorded at "Tests ready"**,
  which also catch tests rewritten while `pnpm test` runs — something the guard can never see.

### Fail mode — fail closed, exit-2 aware
- Claude Code blocks a tool **only on exit code 2**; any other non-zero is non-blocking (fails open). So
  the hook command is **`spine-guard || exit 2`**.
- The guard enforces its **own short deadline** and exits 2 on reaching it (not relying on the 60 s hook
  timeout).
- It **never spawns processes**, and treats `tool_input` as **untrusted data** (hooks run outside the
  sandbox with full access).
- **No off switch** in `spine.yaml` or env; a misbehaving guard is handled by rolling back to the
  previous tarball (ADR-001).
- **Deny Edit/Write on `~/.claude/**`**, so an agent can't slip `disableAllHooks` into user settings via
  a reflex-approved prompt.

## Consequences

- **Easier:** constant-time guard; one hook covers all agents and future tools default-deny; `active.json`
  can't drift from the log; defence-in-depth (sandbox + guard tripwire + submit-time diff/hash) means no
  single layer is load-bearing.
- **Harder:** the role model depends on Claude Code's `agent_type` in hook input (verify against current
  docs); the `|| exit 2` wrapper and the self-deadline are easy to get wrong; `~/.claude/**` denies and
  the guard-bin path are more human-applied settings.
- **Must now be true:** P05 builds the guard bin (agent_type role, `active.json` reader, realpath scope
  match, per-role shape allowlist, self-deadline, `|| exit 2`); P03/P04 write `active.json` inside the
  state lock with the event `seq` and record test-file hashes at "Tests ready"; submit enforces the scope
  diff + test-file-hash checks (ADR-009); the human installs the global hook and the `~/.claude/**`
  denies (Topic 12).
