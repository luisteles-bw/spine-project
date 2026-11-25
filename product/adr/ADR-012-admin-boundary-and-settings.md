---
id: ADR-012
type: adr
title: Human-only boundary & settings — OS-enforced spine-admin binary, consolidated hardened settings
stage: architecture
status: accepted
superseded_by:
version: 6
refs: [SEC-001, SEC-002, SEC-007, REQ-013]
visibility: internal
author: architect
updated: 2026-11-25
---

## Context

The human-only gate commands (`approve`/`reject`) must refuse inside an agent's shell (SEC-001, REQ-013).
But the env var and a TTY are **not boundaries**: the VS Code extension sets `CLAUDECODE=1` in the human's own integrated
terminal (an env check would refuse the human), and `script` can give an agent a TTY. The boundary must
be **OS-enforced** — the sandbox. This topic also consolidates the settings model (SEC-007, REQ-050)
that ADR-006/009/010/011 deferred here.

## Decision

### OS-enforced human-only boundary — the `spine-admin` binary
- Human-only commands — `approve`, `reject`, `phase cut`, `repair` (torn-line), `init`, `upgrade`,
  `import`, `setup` — live in a **separate `spine-admin` binary that is NOT in `sandbox.excludedCommands`**.
- So when an **agent** runs `spine-admin`, it runs **sandboxed**, and `denyWrite` on the event
  log/state blocks it whatever env or TTY tricks it tries. The **human** runs `spine-admin` in a normal
  terminal **outside Claude Code** (no sandbox), so it works.
- The main **`spine` binary carries no human-only code**, so `sandbox.excludedCommands: ["spine *"]` (which
  runs `spine` unsandboxed to write state) can't reach admin functions.
- A **Bash `deny spine-admin *`** gives agents a clear refusal instead of a confusing sandbox error.
- `spine-admin` shows what is being approved and its hash, then asks **y/N** — UX, not the boundary.
- Env var / TTY are **not** used as the security check.

### Three binaries
- `spine` — agent + main session; excluded from the sandbox (writes state).
- `spine-guard` — the PreToolUse guard (ADR-010).
- `spine-admin` — human-only; **not** excluded, so the sandbox blocks agents.

### Consolidated settings — two-tier (D7)
The hardening keys live in `~/.claude/settings.json` (machine-level, applied once per machine); the
project-specific keys live in `.claude/settings.json` (workspace). Exact keys + timing are the plan's
settings table (the operational source of truth); this ADR gives the model.

**Machine-level (`~/.claude/settings.json`) — applied by `spine-admin setup`, once per machine**
These keys are set at **user scope deliberately**: a user-level value is authoritative — a user-level
`false` holds even when a project settings file sets `true` — and one user file covers every workspace,
so an agent cannot relax them by editing a project `.claude/settings.json`. Per the CC settings
reference the first three have scope **Any file** (they would also take from the workspace, but user
scope is chosen for precedence + coverage); only `strictAllowlist` is strictly user/managed-only:
- `sandbox.failIfUnavailable: true` — a missing sandbox must fail, never silently run unsandboxed.
- `sandbox.allowUnsandboxedCommands: false` — a user-level `false` overrides any project `true`.
- `sandbox.excludedCommands: ["spine *"]` — only the main `spine` runs unsandboxed to write state.
- `sandbox.network.strictAllowlist: true` (no `allowedDomains` → agent Bash has no network — D2).
  This one is **truly user/managed-only** (scope: User or managed); requires **Claude Code ≥ v2.1.219**;
  P01-T05 AC-4 confirms it is recognised on the installed version. (Credential *masking* would also be
  user/managed-only, but the spine does not use masking — see the workspace `sandbox.credentials` entry.)

**Workspace (`.claude/settings.json`) — applied by `spine-admin init`/`upgrade`**
- `sandbox.enabled: true`
- `sandbox.filesystem.denyWrite`: event-log dir, `STATE.md`, `project/.git`, `code/.git`,
  `spine.yaml`, **plus a matching `denyWrite` for every Edit/Write deny** (`.claude`, `~/.claude`,
  `CLAUDE.md`, `.mcp.json`, `spec.md`, shell rc files) — docs don't promise Edit denies stop Bash
  writes.
- `sandbox.filesystem.denyRead`: `.env*`, the WSL keychain fallback file, home credentials
  (`~/.ssh`, `~/.aws`, `~/.config/gh`, `~/.npmrc`, `~/.netrc`, `~/.git-credentials`)
- `sandbox.credentials`: token env vars with **`mode: "deny"`**. Masking (`mode: "mask"`) is **not**
  used — now or as a future option: it needs `sandbox.network.tlsTerminate` + an `injectHosts`
  destination reachable through `allowedDomains`, which the no-network agent posture forbids, and on
  macOS (tier 1) `mask` is applied as `deny` regardless. This is a workspace-scope key (CC honours it
  from `.claude/settings.json`). **Check secrets** (e.g. the CMS build token) are not handled here at
  all — they are injected per-check by spine's `@anthropic-ai/sandbox-runtime` wrapper (ADR-011), a
  layer separate from Claude Code's agent-session sandbox.
- `sandbox.network.allowedDomains: []` (documentation duplicate of the user-level strictAllowlist)
- **Permissions** (exact keys: plan's settings table):
  - `allow`: `Bash(spine *)` (excluded commands still follow permission rules), read-only `pnpm`/`git`;
    **`git add`/`commit`/`switch` until switch-over** (D1), then denied.
  - `ask`: `Bash(spine pr *)`, `WebFetch` (ask is evaluated before allow).
  - `deny`: `Bash(spine-admin *)`, `Bash(gh *)` (agents never get `gh`), git push/merge/rebase/reset/
    checkout/clean/branch-D/tag, **dependency installs** (`pnpm add/remove/up/install/i/update/create`,
    `pnpm dlx`, `npx`, `npm`, `yarn`, `bunx`, `corepack` — D6), `cat *.env*` / Read `.env*`,
    Edit/Write `.claude/**` · `~/.claude/**` · `spine.yaml` · **shell rc files** (`~/.zshrc`,
    `~/.zprofile`, `~/.bashrc`, `~/.bash_profile`, `~/.profile`), `security`, `secret-tool`; and
    **from switch-over** `project/state/**`.
  - `permissions.disableBypassPermissionsMode: "disable"` (under `permissions`).
- **`disableAutoMode: "disable"`** — a **top-level** key (not under `permissions`), per the CC settings
  reference.
- **Hooks**: one global PreToolUse `spine-guard || exit 2` — **added only after `spine-guard` exists**.
- **Env**: `GIT_OPTIONAL_LOCKS=0`.
- Duplicate copies of machine-level keys are written here as **documentation only** — nothing
  depends on them taking effect from workspace scope.

### Template provenance, enforcement & timing
- `spine-admin setup` reads the machine-level template from the installed package, shows a diff of
  `~/.claude/settings.json`, and asks y/N. It never edits the workspace file.
- `spine-admin init/upgrade` read the workspace template from the installed package (never
  `code/claude/`), and **show a diff before writing** — agents cannot pre-stage a weakened template.
- `spine-admin init` and `spine doctor` **exit 3** if any machine-level key is absent or weakened in
  `~/.claude/settings.json`.
- Until `spine-admin setup` exists, the human applies the machine-level block by hand; the H-track
  carries this as a prerequisite before P01.
- **Phased:** machine-level block applied before P01 (H-track); baseline workspace settings at P02
  (incl. the `spine-admin *` / `gh` / keychain / `.claude` / `~/.claude` denies, bypass/auto
  disables); **state/git `denyWrite`** switches on at switch-over; **guard hook** added only after
  `spine-guard` is installed.
- P01 probes each user-level key's effect from `~/.claude/settings.json`; also confirms
  `allowUnsandboxedCommands: false` from user settings does **not** trigger admin-required mode
  (only managed/`--settings` do); and confirms `sandbox.network.strictAllowlist` is recognised on
  the installed CC and that the version is ≥ v2.1.219 (P01-T05 AC-4).

## Consequences

- **Easier:** the human-only boundary is OS-enforced, not spoofable; `failIfUnavailable` makes the
  whole deny set fail-safe; agents can't tamper with the settings that bind them (package-sourced
  templates + diff); no `gh` reflex-approvals; machine-level keys work in all CC modes.
- **Harder:** three binaries + `spine-admin setup`; `spine-admin` must stay out of
  `sandbox.excludedCommands`; ordering rules (machine-level block before P01, baseline-before-guard-hook,
  state-denies-at-switch-over) must be followed or the session bricks; workspace-scope CC keys and
  the full machine-level key list must be verified against current docs via P01-T05.
- **Must now be true:** the machine-level block (`~/.claude/settings.json`) is applied before P01;
  `spine-admin init` exits 3 if it is absent; the baseline workspace settings ship with P02
  (`failIfUnavailable:true` duplicate, the `spine-admin *` / `gh` / keychain / `.claude` / `~/.claude`
  denies, bypass/auto disables); the `spine-admin` binary and `spine-guard` land before switch-over;
  the human applies the state/git hardening at switch-over via `spine-admin upgrade`; `/approve`
  becomes `spine-admin approve` after switch-over. Exact keys + timing live in the plan's settings
  table. Phases: see `I01-PLAN`'s ADR→phase table.
- **Amended 2026-11-23:** added `import` to the human-only list; added `sandbox.network: none` (D2), the
  dependency-install denies (D6) and shell-rc denies (PATH/alias hijack, SEC-020); `git add/commit/switch`
  stay allowed until switch-over (D1); exact keys/timing deferred to the plan table; phase numbers
  removed; visibility → internal.
- **Amended 2026-11-24 (ADR-012 review, D7):** two-tier settings split — machine-level keys
  (`sandbox.failIfUnavailable`, `sandbox.allowUnsandboxedCommands`, `excludedCommands`,
  `sandbox.network.strictAllowlist`, `sandbox.credentials` masks) move to `~/.claude/settings.json`
  written by new `spine-admin setup`; workspace retains sandbox.enabled, denyWrite/denyRead,
  permissions, hook, env; `spine-admin setup` added to human-only list; `spine-admin init` /
  `spine doctor` exit 3 if machine-level block absent; `sandbox.network: none` replaced with correct
  key structure; fully-qualified key paths used throughout; H-track H0 added.
- **Amended 2026-11-24:** `strictAllowlist` key path marked **pending P01-T05 AC-4** (docs show both
  `sandbox.strictAllowlist` and `sandbox.network.strictAllowlist`); noted the **CC ≥ v2.1.219**
  requirement.
- **Amended 2026-11-24 (stage review, F1/F2/F3):** corrected three key facts against current CC docs.
  (F1) the exclusion key is **`sandbox.excludedCommands`** (nested), not top-level `excludedCommands` —
  a top-level key is silently ignored, which would fail the "only `spine` writes state" boundary open;
  corrected throughout. (F2) the network allowlist key is resolved to **`sandbox.network.strictAllowlist`**
  (no `sandbox.strictAllowlist` exists); the "pending both paths" note is retired and P01-T05 AC-4 is now
  a confirm-on-version check. (F3) `sandbox.credentials` uses **`mode: "deny"`**, not masking — masking
  needs TLS-termination + a reachable `injectHosts`, impossible under the no-network posture, and macOS
  applies `mask` as `deny`; `sandbox.credentials` moved to the workspace tier (it is honoured from
  workspace scope, matching the plan's P02 placement).
- **Amended 2026-11-25 (stage-review decisions):** (1) corrected the D7 rationale — the three
  machine-level sandbox keys have scope **Any file**; they are placed at user scope for **precedence +
  coverage** (a user-level `false` overrides a project `true`, one file covers every workspace), not
  because the workspace file ignores them. Only `strictAllowlist` (and credential masking, unused) is
  truly user/managed-only. No placement change. (2) `disableAutoMode` is a **top-level** key, not under
  `permissions`; `permissions.disableBypassPermissionsMode` stays under `permissions`. (3) `mode: "deny"`
  for `sandbox.credentials` is final (no masking now or later); check secrets are injected by spine's
  sandbox-runtime wrapper (ADR-011), not by CC's agent-session sandbox. P01-T05 gains a `claude doctor`
  acceptance check that the full settings are accepted with no rejected entries.
