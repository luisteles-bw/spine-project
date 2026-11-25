---
id: P01-T02
type: task
title: sandbox.excludedCommands lets spine write, blocks a non-excluded binary
increment: I01
stage: development
parent: P01
status: planned
version: 2
refs: [SEC-002, ADR-012]
scope:
  touch: ["project/increments/I01-spine-mvp/3-development/P01-harness-spike/probes/excluded/**"]
  forbid: [".claude/**", "spine.yaml"]
size: S
estimate_h: 1
tdd: false
criteria:
  - { id: AC-1, check: manual, text: "A stub command matching sandbox.excludedCommands [\"spine *\"] writes to the protected state-dir successfully (it runs unsandboxed)" }
  - { id: AC-2, check: manual, text: "A non-excluded stub (e.g. spine-admin) attempting the same write is blocked by denyWrite — confirming the admin boundary of ADR-012 is OS-enforced, not env/TTY based" }
billing: none
visibility: internal
author: architect
updated: 2026-11-24
---

## Goal
Confirm the asymmetry ADR-012 depends on: an **excluded** `spine *` command can write state, while a
**non-excluded** binary (the `spine-admin` stand-in) running the same write is blocked by the sandbox.

## Context
This is the whole human-only boundary: `spine-admin` is kept out of `sandbox.excludedCommands`, so an
agent that runs it is sandboxed and `denyWrite` stops it. The probe uses stub scripts named `spine` and
`spine-admin` that only try to append to the scratch state-dir.

## Steps
1. Reuse T01's fixture; add `sandbox.excludedCommands: ["spine *"]`.
2. Run a stub `spine probe-write` that appends to `<state-dir>`; record success.
3. Run a stub `spine-admin probe-write` that appends to `<state-dir>`; record that it is blocked.
4. Note the Claude Code version.

## Out of scope
- The real `spine`/`spine-admin` binaries (don't exist yet).
- Testing actual approve logic (P10).
