---
id: SPEC-ERRATA
type: errata
title: Errata to SPEC v0.4 and the write-protected bootstrap files
stage: architecture
status: draft
version: 1
refs: [SPEC, ARCH, ADR-010, ADR-011, ADR-012, ADR-013]
visibility: internal
author: architect
updated: 2026-11-23
---

`spec.md`, `CLAUDE.md` and `.claude/` are write-protected (the human's). The architecture stage changed
some of their wording; the corrections live here (and, for settings, in the plan's settings table). The
originals stand as the approved record — read them **through** this errata. (Needs the `errata` type added
to the schema enum in P03; additive, per ADR-004.)

## `spec.md`

| § / line | Original wording | Superseded by |
| --- | --- | --- |
| Spine CLI (l.344); CR "Decided" (l.327) | `spine approve` / `spine reject`, incl. `spine approve CR-003 --client … --billing hourly` | **`spine-admin approve` / `spine-admin reject`** — human-only, OS-enforced (ADR-012) |
| Spine CLI (l.339, l.691); Workspace (l.74); Build order (l.831) | `spine init …`, `spine upgrade` | **`spine-admin init` / `spine-admin upgrade`** — human-only (ADR-012, ADR-013) |
| Lifecycles (l.285); spine.yaml (l.377) | "passes only with `spine approve`" / "only `spine approve` passes these" | **`spine-admin approve`** (ADR-012) |
| Agents (l.482, l.508, l.525) | Per-agent hook `spine guard --role coder`; `guard.sh`; "the per-agent hook means spine guard always knows the role" | **One global PreToolUse hook `spine-guard \|\| exit 2`**, role from the hook input's **`agent_type`** (ADR-010); binary is **`spine-guard`** |
| Agents, settings.json example (l.543–559) | The inline `permissions` block | Superseded by the **consolidated settings model** (ADR-012 + plan "Human-applied settings") |
| Agents, next.md example (l.538) | "Never run `spine approve` or `spine reject`" | Approvals are human-only in a terminal; agents never run `spine-admin *` (denied) (ADR-012) |
| Client code repo (l.116) | "The contract … is the root `package.json` scripts … it only runs `pnpm lint/typecheck/test/build`" | Scripts still exist for CI/humans (REQ-002), but the spine's **`check` calls tools directly** (`pnpm exec vitest/eslint/tsc`), never the scripts (ADR-011) |
| Spine CLI (l.335) | "Nineteen commands" (one `spine`) | Split across **three binaries** — `spine` (agent+main, excluded), `spine-guard` (hook), `spine-admin` (human-only, not excluded) (ADR-012) |
| Secrets (l.618) | "Turn on Claude Code's Bash sandboxing too, if your version offers it" | Sandbox is **mandatory** (`sandbox.enabled` + `failIfUnavailable: true`); agent Bash network is **none** (plan settings; ADR-011/012) |

## `CLAUDE.md`

Bootstrap instructions; superseded at switch-over when the agent/command files are regenerated from the
package templates via `spine-admin upgrade` (ADR-016). No correction needed before then — its "Git,
bootstrap only" allowance matches D1 (git writes stay allowed until switch-over).

## `.claude/`

No edits here (write-protected and bootstrap-correct: the command files already use `/approve` and
`STATE.md`, not `spine approve`). The **target** `settings.json` is the plan's settings table; at
switch-over `spine-admin upgrade` installs the package templates and replaces `/approve`·`/reject` with
stubs pointing at `spine-admin` (ADR-016).
