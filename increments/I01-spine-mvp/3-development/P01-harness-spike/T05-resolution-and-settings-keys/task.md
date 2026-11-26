---
id: P01-T05
type: task
title: spine resolution and settings-key probes
increment: I01
stage: development
parent: P01
status: planned
version: 6
refs: [SEC-020, ADR-012, ADR-017]
scope:
  touch: ["project/increments/I01-spine-mvp/3-development/P01-harness-spike/probes/resolution/**"]
  forbid: [".claude/**", "spine.yaml"]
size: S
estimate_h: 1
tdd: false
criteria:
  - { id: AC-1, check: manual, text: "Determine how Claude Code matches sandbox.excludedCommands [\"spine *\"]: with a stub `spine` earlier on PATH (the required test), record whether a PATH entry can shadow the excluded binary (SEC-020). The shell-alias case is optional and, if run, must restore `~/.zshrc` afterwards" }
  - { id: AC-2, check: manual, text: "Every settings key the switch-over config relies on (sandbox.enabled, sandbox.failIfUnavailable, sandbox.allowUnsandboxedCommands, sandbox.excludedCommands, sandbox.network.allowedDomains, sandbox.network.strictAllowlist, sandbox.filesystem.denyWrite, sandbox.filesystem.denyRead, sandbox.credentials, permissions.disableBypassPermissionsMode, top-level disableAutoMode) is recognised by the installed Claude Code version; any unknown key is recorded" }
  - { id: AC-3, check: manual, text: "For sandbox.allowUnsandboxedCommands: false, sandbox.failIfUnavailable: true, sandbox.excludedCommands, and sandbox.network.strictAllowlist: verify which settings-file scope (workspace .claude/settings.json vs user ~/.claude/settings.json vs managed settings) is required for each key to take effect in admin-required sandbox mode; record exact behaviour observed" }
  - { id: AC-4, check: manual, text: "Confirm `sandbox.network.strictAllowlist: true` is recognised and takes effect on the installed Claude Code (no top-level `sandbox.strictAllowlist` exists per current docs), and that the installed version is v2.1.219 or later (strictAllowlist requires it). Record the version." }
  - { id: AC-5, check: manual, text: "Running `claude doctor` with the full switch-over settings loaded (machine-level + workspace) reports no rejected or unknown settings entries — every key in AC-2 is accepted by the installed Claude Code, with disableAutoMode at top level and disableBypassPermissionsMode under permissions" }
billing: none
visibility: internal
author: architect
updated: 2026-11-26
---

## Goal
Confirm the excluded-`spine` boundary can't be shadowed by an alias or PATH entry, and that every
settings key the hardened config uses actually exists in the installed Claude Code — the assumptions
ADR-012 / ADR-017 and the preflight checks (SEC-020) depend on.

## Context
`sandbox.excludedCommands` runs `spine` unsandboxed; if Claude Code matches the literal word rather than
a resolved path, an alias or workspace PATH entry could hijack it (SEC-020). And the settings model is
worthless if a key is silently ignored by this CC version. Preflight / `spine doctor` enforce both
later; here we only learn the behaviour.

## Steps
1. Put a stub `spine` earlier on `PATH` (in the probe-only PATH dir) and run `spine`; record what
   executes and whether `sandbox.excludedCommands` still matched. Optionally also define a shell alias
   `spine` to repeat the test — if you do, restore `~/.zshrc` afterwards.
2. Load the full switch-over `settings.json`; for each key above, confirm Claude Code accepts it (no
   "unknown setting" warning) on this version. Record the CC version.
3. Run `claude doctor` with the full settings loaded and record that it reports no rejected/unknown
   entries (AC-5).

## Out of scope
- Building preflight / `spine doctor` (later phases).
- Fixing a shadowing behaviour (a re-plan / CR if it proves exploitable).
