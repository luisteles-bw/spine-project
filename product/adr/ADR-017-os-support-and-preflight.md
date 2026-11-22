---
id: ADR-017
type: adr
title: OS support & preflight — macOS tier 1, Linux/WSL2 tier 2, per-command preflight, self-audit
stage: architecture
status: accepted
superseded_by:
version: 1
refs: [REQ-083, SEC-007]
visibility: client
author: architect
updated: 2026-11-22
---

## Context

REQ-083: the spine runs on macOS and Linux, Windows through WSL. Earlier ADRs spread OS-specific
surface (keychain, sandbox, locking, line endings), so support must be stated honestly and the
environment — including the spine's own hardening (SEC-007) — must be checked early and legibly.

## Decision

### Support tiers
- **macOS — tier 1:** daily use; the red-team checklist (ADR-015) is verified here. **Security
  guarantees are claimed only for tier 1.**
- **Linux & WSL2 — tier 2:** exercised in CI, but not red-teamed until agent sessions actually run there.
- **Native Windows is unsupported.** Windows is supported only through **WSL2**, which runs the Linux
  paths (`secret-tool` or the 0600 fallback, bwrap).

### WSL2 constraints (preflight-enforced)
- The workspace must live on the **Linux filesystem (`~/…`), never under `/mnt/c`** — there `chmod 0600`
  doesn't hold (breaking the secrets fallback), case/symlinks differ, and it's slow. **Preflight refuses
  `/mnt/*` paths and WSL1** (the sandbox needs WSL2).
- In VS Code on Windows, **Claude Code must run inside the WSL remote**, not the Windows side (native =
  unsandboxed, and `failIfUnavailable` then stops it).

### Preflight & `spine doctor`
- **Each command declares the tools it needs**; preflight checks **only those** before doing any work —
  `spine status` needs nothing external, `spine check` needs the sandbox runtime, the PR commands need
  `gh`. Fast commands stay fast; nothing fails halfway. Missing → **exit 3** with one-line remediation.
- The **guard never runs preflight** (ADR-010: it never spawns processes).
- **`spine doctor`** prints the full report **and audits the hardening**: the workspace settings match the
  package template; `sandbox.enabled`, `failIfUnavailable` and `allowUnsandboxedCommands: false` are set;
  the guard hook is present; and **no `settings.local.json` or user-level setting weakens them**.
- **After switch-over, state-changing commands refuse to run (exit 3) if the sandbox or the guard hook is
  off** — the spine won't mutate state unless its own protections are active.

## Consequences

- **Easier:** an honest, legible support story; fast commands stay dependency-light; environment and
  self-hardening problems fail early with remediation; the spine refuses to run unprotected after
  switch-over.
- **Harder:** per-command tool declarations must be maintained; `spine doctor` must know the expected
  settings template and detect weakening overrides; the WSL2 path/version checks add preflight logic.
- **Must now be true:** P01 builds the preflight framework (per-command tool needs, exit 3 + remediation)
  and `spine doctor` (including the hardening self-check); the WSL2 guards (`/mnt/*`, WSL1, filesystem)
  live in preflight; the "refuse state changes if unprotected" check lands with the switch-over (P04);
  the tier-1-only security claim is documented in `security.md`.
