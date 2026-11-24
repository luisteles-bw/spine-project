---
id: P01-T05
type: task
title: spine resolution and settings-key probes
increment: I01
stage: development
parent: P01
status: planned
version: 3
refs: [SEC-020, ADR-012, ADR-017]
scope:
  touch: ["project/increments/I01-spine-mvp/3-development/P01-harness-spike/probes/resolution/**"]
  forbid: [".claude/**", "spine.yaml"]
size: S
estimate_h: 1
tdd: false
criteria:
  - { id: AC-1, check: manual, text: "Determine how Claude Code matches excludedCommands [\"spine *\"]: with a stub `spine` earlier on PATH, and with a shell alias `spine`, record whether either changes what runs — i.e. whether an alias/PATH entry could shadow the excluded binary (SEC-020)" }
  - { id: AC-2, check: manual, text: "Every settings key the switch-over config relies on (sandbox.enabled, failIfUnavailable, allowUnsandboxedCommands, excludedCommands, sandbox.network.allowedDomains, strictAllowlist (key path per AC-4), sandbox.filesystem.denyWrite, sandbox.filesystem.denyRead, sandbox.credentials, disableBypassPermissionsMode, disableAutoMode) is recognised by the installed Claude Code version; any unknown key is recorded" }
  - { id: AC-3, check: manual, text: "For allowUnsandboxedCommands: false, failIfUnavailable: true, excludedCommands, and strictAllowlist: verify which settings-file scope (workspace .claude/settings.json vs user ~/.claude/settings.json vs managed settings) is required for each key to take effect in admin-required sandbox mode; record exact behaviour observed" }
  - { id: AC-4, check: manual, text: "Resolve the strictAllowlist key path: the docs show both `sandbox.strictAllowlist` and `sandbox.network.strictAllowlist` — record which one the installed Claude Code actually reads (set each in turn, observe which takes effect), and confirm the installed version is v2.1.219 or later (strictAllowlist requires it). Record the version." }
billing: none
visibility: internal
author: architect
updated: 2026-11-24
---

## Goal
Confirm the excluded-`spine` boundary can't be shadowed by an alias or PATH entry, and that every
settings key the hardened config uses actually exists in the installed Claude Code — the assumptions
ADR-012 / ADR-017 and the preflight checks (SEC-020) depend on.

## Context
`excludedCommands` runs `spine` unsandboxed; if Claude Code matches the literal word rather than a
resolved path, an alias or workspace PATH entry could hijack it (SEC-020). And the settings model is
worthless if a key is silently ignored by this CC version. Preflight / `spine doctor` enforce both
later; here we only learn the behaviour.

## Steps
1. Put a stub `spine` earlier on `PATH`, then define a shell alias `spine`; run `spine` and record what
   executes and whether `excludedCommands` still matched.
2. Load the full switch-over `settings.json`; for each key above, confirm Claude Code accepts it (no
   "unknown setting" warning) on this version. Record the CC version.

## Out of scope
- Building preflight / `spine doctor` (later phases).
- Fixing a shadowing behaviour (a re-plan / CR if it proves exploitable).
