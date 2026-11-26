---
id: P01-T01
type: task
title: Sandbox denyWrite blocks a Bash append
increment: I01
stage: development
parent: P01
status: planned
version: 3
refs: [SEC-002, ADR-006, ADR-012]
scope:
  touch: ["project/increments/I01-spine-mvp/3-development/P01-harness-spike/probes/denywrite/**"]
  forbid: [".claude/**", "spine.yaml"]
size: S
estimate_h: 1
tdd: false
criteria:
  - { id: AC-1, check: manual, text: "When an agent Bash call runs `echo x >> <state-dir>/probe.txt` under a fixture settings.json whose sandbox denyWrite covers <state-dir>, Claude Code blocks the write and the file is unchanged" }
  - { id: AC-2, check: manual, text: "An Edit/Write to the same path is blocked by an Edit/Write permission deny over the state dir (Edit/Write follow permission rules, not sandbox denyWrite, which governs Bash); and with failIfUnavailable:true a missing sandbox makes a Bash write fail rather than run unsandboxed" }
  - { id: AC-3, check: manual, text: "A sandboxed `cat` / `node -e` read of a `.env` file in a nested directory is blocked by `denyRead` (sandbox path/glob semantics confirmed to cover nested paths)" }
  - { id: AC-4, check: manual, text: "A token env var listed under `sandbox.credentials.envVars` with `mode: \"deny\"` is unavailable to a sandboxed probe that echoes it (documented shape is `credentials.envVars` / `credentials.files`; on macOS tier 1 `mask` is applied as `deny`, and masking would anyway need TLS-termination + network that the no-network posture forbids)" }
billing: none
visibility: internal
author: architect
updated: 2026-11-26
---

## Goal
Confirm that sandbox `denyWrite` (with `failIfUnavailable: true`) actually stops a Bash append into a
protected directory — the assumption ADR-006's "only the spine writes state" rests on.

## Context
ADR-006 and ADR-012 require that agents cannot write `project/state/**` by any means. The docs don't
promise `Edit` denies stop Bash writes, so the sandbox `denyWrite` must. This probe uses a throwaway
fixture, not the real settings.

## Steps
1. Write a fixture `settings.json` enabling the sandbox with `denyWrite` over a scratch `state-dir` and
   `failIfUnavailable: true`, plus an `Edit`/`Write` **permission deny** over the same dir (Edit/Write
   don't obey `denyWrite`) and a `sandbox.credentials.envVars` entry (`mode: "deny"`) for a token var.
2. In a real session, attempt `echo x >> <state-dir>/probe.txt` via Bash; record the result.
3. Attempt an Edit and a Write to the same path (via the Edit/Write tools, not Bash); record the result.
4. Note the Claude Code version.

## Out of scope
- The real workspace settings (untouched).
- Linux/WSL behaviour (tier 2).
