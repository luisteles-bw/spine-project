---
id: ADR-012
type: adr
title: Human-only boundary & settings — OS-enforced spine-admin binary, consolidated hardened settings
stage: architecture
status: accepted
superseded_by:
version: 1
refs: [SEC-001, SEC-002, SEC-007, REQ-013]
visibility: client
author: architect
updated: 2026-11-22
---

## Context

`spine approve`/`reject` must refuse inside an agent's shell (SEC-001, REQ-013). But the env var and a
TTY are **not boundaries**: the VS Code extension sets `CLAUDECODE=1` in the human's own integrated
terminal (an env check would refuse the human), and `script` can give an agent a TTY. The boundary must
be **OS-enforced** — the sandbox. This topic also consolidates the settings model (SEC-007, REQ-050)
that ADR-006/009/010/011 deferred here.

## Decision

### OS-enforced human-only boundary — the `spine-admin` binary
- Human-only commands — `approve`, `reject`, `phase cut`, `repair` (torn-line), `init`, `upgrade` —
  live in a **separate `spine-admin` binary that is NOT in `excludedCommands`**.
- So when an **agent** runs `spine-admin`, it runs **sandboxed**, and `denyWrite` on the event
  log/state blocks it whatever env or TTY tricks it tries. The **human** runs `spine-admin` in a normal
  terminal **outside Claude Code** (no sandbox), so it works.
- The main **`spine` binary carries no human-only code**, so `excludedCommands: ["spine *"]` (which runs
  `spine` unsandboxed to write state) can't reach admin functions.
- A **Bash `deny spine-admin *`** gives agents a clear refusal instead of a confusing sandbox error.
- `spine-admin` shows what is being approved and its hash, then asks **y/N** — UX, not the boundary.
- Env var / TTY are **not** used as the security check.

### Three binaries
- `spine` — agent + main session; excluded from the sandbox (writes state).
- `spine-guard` — the PreToolUse guard (ADR-010).
- `spine-admin` — human-only; **not** excluded, so the sandbox blocks agents.

### Consolidated settings (framework-shipped, applied by `spine-admin init`/`upgrade`)
**Sandbox**
- `allowUnsandboxedCommands: false`
- **`failIfUnavailable: true`** — a missing sandbox dependency must fail, never silently run
  unsandboxed (which would void every `denyWrite`).
- `excludedCommands: ["spine *"]` (only the main `spine`).
- `denyWrite`: event-log dir, `STATE.md`, `project/.git`, `code/.git`, `spine.yaml`, **plus a matching
  `denyWrite` for every Edit/Write deny** (`.claude`, `~/.claude`, `CLAUDE.md`, `.mcp.json`, `spec.md`) —
  the docs don't promise Edit denies stop Bash writes.
- `denyRead`: `.env*`, the WSL keychain fallback file, and home credentials `~/.ssh`, `~/.aws`,
  `~/.config/gh`, `~/.npmrc`, `~/.netrc`, `~/.git-credentials`. Mask token env vars via
  `sandbox.credentials`.

**Permissions**
- `allow`: `Bash(spine *)` (excluded commands still follow permission rules), read-only `pnpm`/`git`.
- `ask`: `Bash(spine pr *)`, `WebFetch` (ask is evaluated before allow).
- `deny`: `Bash(spine-admin *)`, `Bash(gh *)` (agents never get `gh` — spine handles PRs), git write
  verbs, `cat *.env*` / Read `.env*`, Edit/Write `project/state/**` · `.claude/**` · `~/.claude/**` ·
  `spine.yaml`, `security`, `secret-tool`.
- `disableBypassPermissionsMode: "disable"`, `disableAutoMode: "disable"`.

**Hooks**: one global PreToolUse `spine-guard || exit 2` — **added only after `spine-guard` exists**
(with `|| exit 2`, a missing binary blocks every tool call, including the fix).

**Env**: `GIT_OPTIONAL_LOCKS=0`.

### Template provenance & timing
- `spine-admin init/upgrade` read settings templates from the **installed package**, never from
  `code/claude/`, and **show a diff before writing** — otherwise an agent edits
  `code/claude/settings.json` and the next upgrade applies the agent's own permissions.
- **Phased:** baseline now (incl. `failIfUnavailable:true`, `allowUnsandboxedCommands:false`, the
  `spine-admin *` / `gh` / keychain / `.claude` / `~/.claude` denies, bypass/auto disables); the
  **state/git `denyWrite`** set switches on at **switch-over**; the **guard hook** is added only **after
  `spine-guard` is installed**.

## Consequences

- **Easier:** the human-only boundary is OS-enforced, not spoofable; `failIfUnavailable` makes the whole
  deny set fail-safe; agents can't tamper with the settings that bind them (package-sourced templates +
  diff); no `gh` reflex-approvals.
- **Harder:** three binaries to build/install; `spine-admin` must stay out of `excludedCommands`;
  ordering rules (baseline-before-guard-hook, state-denies-at-switch-over) must be followed or the
  session bricks; the exact Claude Code sandbox/permission keys must be verified against current docs.
- **Must now be true:** P01 scaffolds the baseline settings (minus state/git denies and the guard hook)
  with `failIfUnavailable:true`; P04 splits human-only commands into `spine-admin`; P05 adds
  `spine-guard` then the guard hook; the human applies the state/git hardening at switch-over via
  `spine-admin upgrade`; `/approve` becomes `spine-admin approve` after switch-over. (Update `security.md`
  SEC-001 wording to the OS-enforced mechanism.)
