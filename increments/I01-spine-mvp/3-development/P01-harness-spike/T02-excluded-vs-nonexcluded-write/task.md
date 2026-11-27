---
id: P01-T02
type: task
title: sandbox.excludedCommands lets spine write, blocks a non-excluded binary
increment: I01
stage: development
parent: P01
status: planned
version: 4
refs: [SEC-002, ADR-012]
scope:
  touch: ["project/increments/I01-spine-mvp/3-development/P01-harness-spike/probes/excluded/**"]
  forbid: [".claude/**", "spine.yaml"]
size: S
estimate_h: 1
tdd: false
criteria:
  - { id: AC-1, check: manual, text: "A stub command matching sandbox.excludedCommands [\"spine *\"] writes to the protected state-dir successfully (it runs unsandboxed)" }
  - { id: AC-2, check: manual, text: "Running `spine-admin probe-write` (prefix form) is refused by the permission-layer deny `Bash(spine-admin *)` — expected, but this does NOT prove the OS boundary (a prefix rule, not the sandbox)" }
  - { id: AC-3, check: manual, text: "An invocation the `Bash(spine-admin *)` deny rule does not match (e.g. `bash <path>/spine-admin probe-write`) still has its write blocked by sandbox denyWrite — only this proves the admin boundary of ADR-012 is OS-enforced, not env/TTY/permission-prefix based" }
billing: none
visibility: internal
author: architect
updated: 2026-11-27
---

## Goal
Confirm the asymmetry ADR-012 depends on: an **excluded** `spine *` command can write state, while a
**non-excluded** binary (the `spine-admin` stand-in) running the same write is blocked by the sandbox.

## Context
This is the whole human-only boundary: `spine-admin` is kept out of `sandbox.excludedCommands`, so an
agent that runs it is sandboxed and `denyWrite` stops it. The probe uses stub scripts named `spine` and
`spine-admin` that only try to append to the scratch state-dir.

## Steps
1. Reuse T01's fixture; `sandbox.excludedCommands: ["spine *"]` comes from the H0 user-level block. Put
   the stub `spine`/`spine-admin` in a **probe-only PATH dir** (only the probe terminal adds it to `PATH`).
2. Run a stub `spine probe-write` that appends to `<state-dir>`; record success (runs unsandboxed).
3. Run `spine-admin probe-write` (prefix form); record the **permission-layer** refusal (`Bash(spine-admin *)`).
4. Run the same write via an invocation the `Bash(spine-admin *)` deny does **not** match (e.g. `bash <path>/spine-admin probe-write`); record that sandbox **denyWrite** blocks it — the OS boundary. (A bare full path may itself be caught by the deny — see the T05 open-question probe.)
5. Note the Claude Code version.

## Out of scope
- The real `spine`/`spine-admin` binaries (don't exist yet).
- Testing actual approve logic (P10).

## Amendments
- **v4 (2026-11-27), correction — no decision change.** AC-3 + Step 4 reworded: the OS-boundary test is an invocation the `Bash(spine-admin *)` deny does **not** match (e.g. `bash <path>/spine-admin`), not "spine-admin's full path" — in P01-T02 session 1 the deny caught the bare full-path spelling too. The bypass is the `bash <path>` spelling, not a weaker permission mode (session 2 ran `--permission-mode default`; session 1 ran auto mode). **Open question** — whether session 1's bare full-path refusal was the rule or the auto-mode classifier — is deferred to a T05 operator-sheet probe. See STATE log 2026-11-27 + findings F-2.
