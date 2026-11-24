---
id: P01-T03
type: task
title: PreToolUse exit 2 blocks a Bash call; exit 1 does not
increment: I01
stage: development
parent: P01
status: planned
version: 1
refs: [ADR-010]
scope:
  touch: ["project/increments/I01-spine-mvp/3-development/P01-harness-spike/probes/exit2/**"]
  forbid: [".claude/**", "spine.yaml"]
size: S
estimate_h: 0.5
tdd: false
criteria:
  - { id: AC-1, check: manual, text: "A PreToolUse hook that exits 2 blocks the matched Bash call — the command does not run" }
  - { id: AC-2, check: manual, text: "The same hook exiting 1 (or any non-2 code) does NOT block — the call proceeds — confirming the guard command must be `spine-guard || exit 2`" }
  - { id: AC-3, check: manual, text: "With the hook command `spine-guard || exit 2` and `spine-guard` missing or crashing, the tool call is blocked — the `|| exit 2` makes a missing binary fail closed" }
billing: none
visibility: internal
author: architect
updated: 2026-11-22
---

## Goal
Confirm that Claude Code blocks a tool call **only** on PreToolUse exit code 2, so a guard crash or
missing binary fails *open* unless wrapped as `|| exit 2` (ADR-010).

## Context
ADR-010's fail-closed design hinges on this exact behaviour. If any non-zero code blocked, the `|| exit
2` wrapper would be unnecessary; if only 2 blocks, the wrapper is mandatory.

## Steps
1. Add a PreToolUse hook (a 3-line script) that `exit 2` on a marker command; confirm the command is
   blocked.
2. Change it to `exit 1`; confirm the command runs.
3. Record both, and the Claude Code version.

## Out of scope
- The real guard logic (P07).
- Measuring hook latency (P07 budget work).
