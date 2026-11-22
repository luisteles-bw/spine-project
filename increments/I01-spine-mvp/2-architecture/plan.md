---
id: I01-PLAN
type: plan
title: Spine MVP plan
increment: I01
stage: architecture
parent: I01
status: draft
version: 1
refs: [REQUIREMENTS, SECURITY, ARCH, ADR-001, ADR-010, ADR-012, ADR-013, ADR-015, ADR-016, ADR-017]
visibility: internal
author: architect
updated: 2026-11-22
---

## Phases

Billing is `none` for every phase (the spine builds itself). Limits: ≤ 8 tasks and ≤ 24 h per phase.
**Priority** is for I01 completion; the **Dec-13 goal** is reaching the P09 milestone (see the verdict).

| Phase | Stage | Goal | Depends on | Est. h | Priority | Covers |
| --- | --- | --- | --- | --- | --- | --- |
| **P01** | development | **Harness spike** — prove the Claude Code behaviours ADR-006/009/010/012 rest on, on macOS. Gate before building on top | none | 4 | **Must** | de-risks SEC-001/002/004 |
| **P02** | development | Repo, pnpm workspace, dual tsconfig (pure core), tsdown/tsx/eslint/prettier/vitest, Node 24, CI (macOS+Linux, sandbox+network-denied), **baseline hardened settings**, preflight + `spine doctor` skeleton | P01 | 18 | **Must** | REQ-080, REQ-083, REQ-081, REQ-084, SEC-007 |
| **P03** | development | Zod schemas (discriminated union) + committed JSON Schema + Ajv contract test; `yaml` parser + splitter; heading scanner + registry; id index (with line ranges) + ref resolution | P02 | 22 | **Must** | REQ-020, REQ-021, REQ-022 |
| **P04** | development | **Pure core**: event log (seq, hashes, `O_EXCL` lock, recovery), reducer + transition tables + guards, graph projection, replay-stability + full state×event tests | P03 | 24 | **Must** | REQ-010, REQ-011, REQ-014, REQ-023, REQ-082 |
| **P05** | development | CLI core: commander routing + envelope + exit table; `status`, `next`, `context` (budget + plan-time check), `submit` (DoD), `session`, `plan apply` (DoR, limits, split), `cr raise`, `active.json` writer | P04 | 24 | **Must** | REQ-024, REQ-030–034, REQ-016, REQ-015, REQ-060 |
| **P06** | development | Checks (sandbox-runtime, secret inject + redaction + sweep, keychain), git adapter (hooks-off, trailers, `Spine-Seq`, scoped staging), `gh` adapter + tamper-proof `phase_pr`, `check --trace` | P05 | 22 | **Must** | REQ-040–043, REQ-025, SEC-005/006/009/012 |
| **P07** | development | `spine-guard` bin + one global hook; the five agents + slash commands; settings model finalised | P06 | 20 | **Must** | REQ-050, REQ-051, REQ-052, SEC-004/008 |
| **P08** | development | `spine-admin` (approve/reject/phase cut/repair/upgrade/import); CR decide; **switch-over** (import `--dry-run` + projection match, phase-2 settings, guard hook) | P07 | 20 | **Must** | REQ-012, REQ-013, REQ-035, SEC-001/002/003 |
| **P09** | development | `spine init` (+ both repos, `.claude`, `CLAUDE.md`, `.mcp.json`, `spine.yaml`, I01); overlay engine; sandboxed atomic scaffolder; **`nextjs-static`** profile | P05–P08 | 22 | **Must** | REQ-001, REQ-002, REQ-003, REQ-004 |
| **P10** | development | Twenty 2.0 app (spike-first) + one-way REST `sync` (outbox, `spineId`, cache) | P08 | 20 | Must (after Dec-13) | REQ-070, REQ-071 |
| **P11** | development | `increment new` + billing, `ticket`, `time`, `export`, changelog + version tag | P08 | 20 | Should | REQ-061–064, REQ-044, REQ-005 |
| **P12** | quality | Dogfood run on a sample `nextjs-static` project; **red-team checklist**; full-repo security audit; fixes | P09 (P10–P11) | 16 | Must (stage) | measures 1–4 |
| **P13** | delivery | `v0.1.0` release, install guide, release checklist | P12 | 10 | Must (stage) | REQ-044, release |

## Order and rationale

The order is **dependency-driven but prioritised for time to value**:

- **P01 is a spike and a gate.** Everything downstream (the state write-protection, the git hook-proofing,
  the guard, the admin boundary) assumes specific Claude Code behaviours. We prove them on your Mac in a
  real session *first*; if any fails we re-plan before building on a false assumption.
- **P02–P08 are the unavoidable core** beneath every feature: toolchain → schemas → event log/lifecycles →
  CLI → checks/git → guard/agents → admin/switch-over. "Deliver init first" isn't physically possible —
  `init` scaffolds a workspace that the core must already be able to drive.
- **P09 is the value milestone.** When P02–P09 are done, **a client project can be started and driven under
  the spine** (`init` → the `next/submit/check` loop → `spine-admin approve`). That is the Dec-13 target.
- **P10 (Twenty) and P11 (extra commands) come after**, as you asked — they add reporting and breadth, not
  the ability to run a project. P10 is still **Must for I01** (REQ-070/071), just after the milestone.
- **P12 quality and P13 delivery** close the increment (red-team, dogfood, release).

## Schedule verdict (honest)

**Target 2026-12-13 is ~21 calendar days; the Must core (P01–P09) is ≈ 176 h of work**, built largely by
hand through the bootstrap process (slower than normal dev) while you are also selling and delivering
December client work. **Plan on P01–P09 not all landing by the 13th.** Realistic read:

- **Firm by ~2 weeks:** P01–P05 (core + CLI) — the part that must never be wrong.
- **Week-3 stretch:** P06–P09 (checks/git, guard, admin/switch-over, init). `init` + profile fully green by
  the 13th is the tightest item.
- **After the 13th:** P10 Twenty, P11 extra commands, P12 quality, P13 delivery.

**The December client is not blocked on this.** Bootstrap mode (this very process — agents writing the same
documents, you approving by hand) can run a real `nextjs-static` client project *now*, as the brief's risk
mitigation intends. Ship the client in bootstrap mode if needed; fold the spine in as each phase lands.

## Requirement coverage

| Requirement | Phases |
| --- | --- |
| REQ-001, REQ-002, REQ-003, REQ-004 | P09 (REQ-004 also P10) |
| REQ-005 | P11 |
| REQ-010, REQ-011, REQ-014, REQ-023, REQ-082 | P04 |
| REQ-012, REQ-013, REQ-035 | P08 |
| REQ-015 | P05 (split), P08 (cut) |
| REQ-016, REQ-024, REQ-030, REQ-031, REQ-032, REQ-033, REQ-034 | P05 |
| REQ-020, REQ-021, REQ-022 | P03 |
| REQ-025, REQ-040, REQ-041, REQ-042, REQ-043 | P06 |
| REQ-044 | P11, P13 |
| REQ-050, REQ-051, REQ-052 | P07 |
| REQ-060 | P05 (raise), P08 (decide) |
| REQ-061, REQ-062, REQ-063, REQ-064 | P11 |
| REQ-070, REQ-071 | P10 |
| REQ-080, REQ-081, REQ-083, REQ-084 | P02 |

## Human-applied settings — by phase (one place, so none are lost)

Agents can't edit `.claude/` or `spine.yaml`; **you** apply these. Verify exact Claude Code keys against
current docs when writing them (ADR-012).

| When | Setting / action | Why | ADR |
| --- | --- | --- | --- |
| **Baseline (P02, now)** | `sandbox.enabled: true`, `allowUnsandboxedCommands: false`, **`failIfUnavailable: true`** | Without `failIfUnavailable`, a missing sandbox silently voids every `denyWrite` | 006, 012 |
| Baseline (P02) | `excludedCommands: ["spine *"]` | Only the main `spine` runs unsandboxed to write state | 006, 012 |
| Baseline (P02) | `permissions.disableBypassPermissionsMode: "disable"`, `disableAutoMode: "disable"` | Close the mode-switch escape hatches | 012 |
| Baseline (P02) | allow `Bash(spine *)`, read-only `pnpm`/`git`; ask `Bash(spine pr *)`, `WebFetch` | `spine pr` pushes/opens a PR; ask is evaluated before allow | 009, 012 |
| Baseline (P02) | deny `Bash(spine-admin *)`, `Bash(gh *)`, git write verbs, `cat *.env*` / Read `.env*`, Edit/Write `.claude/**` · `~/.claude/**` · `spine.yaml`, `security`, `secret-tool` | Human-only boundary, no `gh` reflex-approvals, no keychain/settings tampering | 009, 011, 012 |
| Baseline (P02) | sandbox `denyRead`: `.env*`, home creds (`~/.ssh`, `~/.aws`, `~/.config/gh`, `~/.npmrc`, `~/.netrc`, `~/.git-credentials`); `sandbox.credentials` masks token env vars | Keep secrets off the agent | 011, 012 |
| Baseline (P02) | sandbox `denyWrite` mirroring **every** Edit/Write deny (`.claude`, `~/.claude`, `CLAUDE.md`, `.mcp.json`, `spec.md`) | Edit denies don't promise to stop Bash writes | 012 |
| Baseline (P02) | env `GIT_OPTIONAL_LOCKS=0` | Read-only `git status` for agents won't write | 009 |
| **Switch-over (P08)** | sandbox `denyWrite` **add**: `project/state/**`, `STATE.md`, `project/.git`, `code/.git`, `spine.yaml` | Only the spine writes state/git, once it owns them | 006, 009, 012 |
| Switch-over (P08) | Install the global PreToolUse hook **`spine-guard \|\| exit 2`** — only now that `spine-guard` exists | `\|\| exit 2` would brick every tool call if the binary were missing | 010, 012 |
| Switch-over (P08) | Tag both repos; `spine-admin upgrade` (package templates + diff); restart Claude Code; run red-team | Reversible cutover; load new settings/hooks | 016, 015 |
| **Per client `init` (P09)** | Add `code/CLAUDE.md`, `code/AGENTS.md` to the write-protected set | Stop an agent leaving standing instructions for later sessions | 013 |
| **Later / per project** | Pin stdio MCP exact versions; add Vercel MCP (project-specific URL) only when hosting is decided | `@latest` = unreviewed local code; shared endpoint leaks other clients | 013 |
| Environment (WSL only) | Workspace on the Linux filesystem (`~/…`), WSL2, Claude Code in the WSL remote | `/mnt/c` breaks `chmod 0600`; native Windows runs unsandboxed | 017 |

## Risks and assumptions

| Risk or assumption | Effect if wrong | Mitigation |
| --- | --- | --- |
| Claude Code's sandbox / `agent_type` / exit-2 behaviours differ from assumed | ADR-006/010/012 don't hold | **P01 spike proves them first**; re-plan on failure |
| The Must core (~176 h) won't fit by 2026-12-13 while selling/delivering | The spine is late for the first client | Reach the loop early; **run the client in bootstrap mode** meanwhile |
| Twenty 2.0 SDK can't express the model | P10 slips | **P08-opening half-day spike**; metadata-API fallback (ADR-014) |
| `@anthropic-ai/sandbox-runtime` (research preview) API shifts | Check runner breaks | Pin it; it's a `new_dependency` gate; isolate behind the process adapter |
| Building by hand is slower than estimated | Schedule slips further | Switch over as early as P08 so the spine builds its own remainder |

## Switch-over task

The switch-over (ADR-016) is the first task block of **P08**: once `status`, `next`, `submit` and
`approve` work, migrate the bootstrap docs, `spine-admin import --dry-run`, verify the normalized
projection matches `STATE.md`, apply the phase-2 settings + guard hook, restart, red-team, and archive
`STATE.md` as `STATE.bootstrap.md`.
