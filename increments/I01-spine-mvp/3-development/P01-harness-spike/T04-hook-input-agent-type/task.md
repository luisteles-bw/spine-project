---
id: P01-T04
type: task
title: PreToolUse input carries agent_type for subagents
increment: I01
stage: development
parent: P01
status: planned
version: 1
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
  - { id: AC-3, check: manual, text: "Under `sandbox.network: none`, an agent Bash command needing the network is blocked without an interactive per-domain prompt; if Claude Code still prompts, record whether a hard deny is possible (D2 depends on this)" }
billing: none
visibility: internal
author: architect
updated: 2026-11-22
---

## Goal
Confirm the guard can learn its role from the hook input's `agent_type` (ADR-010), replacing the spec's
per-agent `--role`.

## Context
ADR-010 uses one global hook keyed on `agent_type`. This probe checks the field is actually present for
subagent calls and absent for the main session, and captures its exact shape/values for the real guard.

## Steps
1. Add a PreToolUse hook that appends the raw input JSON to a log, then exits 0.
2. Trigger a tool call from the main session; then dispatch a subagent that makes a tool call.
3. Compare the two logged payloads; record whether `agent_type` is present and its values.
4. Note the Claude Code version and the exact field name.

## Out of scope
- Building the guard's role mapping (P07).
- Enumerating every built-in subagent type (record what appears).
