---
id: P01-T04
type: task
title: PreToolUse input carries agent_type for subagents
increment: I01
stage: development
parent: P01
status: planned
version: 4
refs: [ADR-010]
scope:
  touch: ["project/increments/I01-spine-mvp/3-development/P01-harness-spike/probes/agent-type/**"]
  forbid: [".claude/**", "spine.yaml"]
size: S
estimate_h: 0.5
tdd: false
criteria:
  - { id: AC-1, check: manual, text: "When a subagent makes a tool call, the PreToolUse hook input JSON includes an agent_type identifying the subagent" }
  - { id: AC-2, check: manual, text: "A main-session tool call has no agent_type (or a documented sentinel), so the guard can map 'no agent_type' to the main-session policy and unknown types to read-only" }
  - { id: AC-3, check: manual, text: "With `sandbox.network.allowedDomains: []` and `sandbox.network.strictAllowlist: true`, an agent Bash command needing the network is denied without an interactive per-domain prompt (D2 depends on this)" }
  - { id: AC-4, check: manual, text: "A scoped subagent that makes at least 3 tool calls in a single run carries the same agent_type on every PreToolUse firing (checking that the absent-agent_type behaviour of CC #90662 — auto-closed not-planned, unverified — does not occur on the pinned CC version; record the CC version)" }
  - { id: AC-5, check: manual, text: "The hook script can WRITE a file into the `denyWrite` state/ dir (a path an agent Bash call is blocked from) — the write succeeding confirms hooks run unsandboxed with full user access, not inside the agent sandbox" }
billing: none
visibility: internal
author: architect
updated: 2026-11-26
---

## Goal
Confirm the guard can learn its role from the hook input's `agent_type` (ADR-010), replacing the spec's
per-agent `--role`.

## Context
ADR-010 uses one global hook keyed on `agent_type`. This probe checks the field is actually present for
subagent calls and absent for the main session, and captures its exact shape/values for the real guard.

## Steps
1. Add a PreToolUse hook that appends the raw input JSON to a log and also attempts to **write** a file
   into the `denyWrite` state/ dir, recording whether the write succeeds; exits 0.
2. Trigger a tool call from the main session; then dispatch a subagent that makes at least 3 tool calls.
3. Compare the logged payloads; record whether `agent_type` is present on every firing and its values.
4. Verify the hook's write into the `denyWrite` state/ dir succeeded (AC-5: hooks are unsandboxed).
5. Note the exact Claude Code version; flag if any `agent_type` is absent mid-run (CC #90662 present).

## Out of scope
- Building the guard's role mapping (P09).
- Enumerating every built-in subagent type (record what appears).
