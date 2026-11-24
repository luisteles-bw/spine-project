---
id: I01-PLAN
type: plan
title: Spine MVP plan
increment: I01
stage: architecture
parent: I01
status: draft
version: 3
refs: [REQUIREMENTS, SECURITY, ARCH, ADR-001, ADR-009, ADR-010, ADR-011, ADR-012, ADR-013, ADR-014, ADR-015, ADR-016, ADR-017, ADR-018]
visibility: internal
author: architect
updated: 2026-11-24
---

> **v2 (2026-11-23), pre-gate review.** Split old P05 (CLI) and P06 (checks+git) so no phase breaks the
> spine's own ≤ 8-task / ≤ 24-h limits; renumbered to 15 phases. Added the ADR→phase table (phase numbers
> now live here, not in the ADRs), the parallel human track, the STATE.md-renderer assignment, and the
> network / dependency-install / `project/` backup decisions (D1–D6).
>
> **v3 (2026-11-24):** wired in independent design reviews (ADR-018) — REQ-090 → P06, REQ-091 → P09, a
> bootstrap settings row, and coverage.

## Phases

Billing is `none` for every phase (the spine builds itself). Limits: ≤ 8 tasks and ≤ 24 h per phase.
**Priority** is for I01 completion; the **Dec-13 goal** is reaching the **P11 milestone** (see the verdict).

| Phase | Stage | Goal | Depends on | Est. h | Priority | Covers |
| --- | --- | --- | --- | --- | --- | --- |
| **P01** | development | **Harness spike** — prove, on macOS, the Claude Code behaviours the security model rests on. Gate before building on top | none | 6 | **Must** | de-risks SEC-001/002/004/007/011 |
| **P02** | development | Repo, pnpm workspace, dual tsconfig (pure core), tsdown/tsx/eslint/prettier/vitest, Node 24, CI (macOS+Linux, **sandbox + network-denied**, verify bwrap on the runner), **baseline hardened settings**, preflight + `spine doctor` skeleton | P01 | 18 | **Must** | REQ-080/081/083/084, SEC-007 |
| **P03** | development | Zod schemas (discriminated union) + committed JSON Schema + Ajv contract test; `yaml` parser + splitter; heading scanner + registry; id index (line ranges) + ref resolution | P02 | 20 | **Must** | REQ-020/021/022 |
| **P04** | development | **Pure core**: event log (seq, hashes, `O_EXCL` lock, recovery), reducer + transition tables + guards, graph projection, replay-stability + full state×event tests | P03 | 22 | **Must** | REQ-010/011/014/023/082 |
| **P05** | development | **CLI read side**: commander routing + envelope + exit table + renderer; `status`, `next`, `context` (budget + plan-time check), `session`, `doctor` | P04 | 16 | **Must** | REQ-024/030/031/034 |
| **P06** | development | **CLI write side**: `submit` (DoD: validate + scope-diff + test-hashes), `plan apply` (DoR, limits, split), `cr raise`, `active.json` writer (inside the state lock) | P05 | 16 | **Must** | REQ-016/032/033/060, REQ-015 (split), REQ-090 |
| **P07** | development | **Checks & secrets**: sandbox-runtime runner, per-check secret inject + layered redaction + post-check sweep, keychain adapter (+ WSL fallback), `check --trace` | P06 | 18 | **Must** | REQ-040/041/025, SEC-005/006/011/012 |
| **P08** | development | **Git & PR**: git adapter (hooks-off, `--trailer`, `Spine-Seq`, scoped staging), `gh` adapter, tamper-proof `phase_pr` (SHA + ancestry) | P07 | 16 | **Must** | REQ-042/043, SEC-009 |
| **P09** | development | **Guard & Claude assets**: `spine-guard` bin + one global `agent_type` hook; the five agents + slash commands; settings model finalised | P08 | 20 | **Must** | REQ-050/051/052/091, SEC-004/008 |
| **P10** | development | **`spine-admin` + switch-over**: approve/reject/phase cut/repair/upgrade/import; CR decide; switch-over (import `--dry-run` + projection match, phase-2 settings, guard hook); **renders the generated `STATE.md`** | P09 | 20 | **Must** | REQ-012/013/035, SEC-001/002/003 |
| **P11** | development | **`init` + `nextjs-static`**: `spine-admin init` (+ both repos, `.claude`, `CLAUDE.md`, `.mcp.json`, `spine.yaml`, I01); overlay engine; sandboxed atomic scaffolder; the profile | P06–P10 | 22 | **Must** | REQ-001/002/003/004 |
| **P12** | development | Twenty 2.0 app (spike-first) + one-way REST `sync` (outbox, `spineId`, cache) | P10 | 20 | Must (after milestone) | REQ-070/071 |
| **P13** | development | `increment new` + billing, `ticket`, `time`, `export`, `upgrade`, changelog + version tag | P10 | 20 | Should | REQ-005/044/061/062/063/064 |
| **P14** | quality | Dogfood run on a sample `nextjs-static` project; **red-team checklist** (incl. `spine-admin approve` refused from an agent shell); full-repo security audit; fixes | P11 (P12–P13) | 16 | Must (stage) | measures 1–4 |
| **P15** | delivery | `v0.1.0` release, install guide, release checklist | P14 | 10 | Must (stage) | REQ-044, release |

**P11 is the value milestone.** When P02–P11 are done, a client project can be started and driven under
the spine (`spine-admin init` → the `next`/`submit`/`check` loop → `spine-admin approve`).

## Order and rationale

- **P01 is a spike and a gate** (see its expanded probes): everything downstream assumes specific Claude
  Code sandbox / permission / hook behaviours; we prove them first and re-plan on any failure.
- **P02–P10 are the unavoidable core** (toolchain → schemas → event log/lifecycles → CLI read → CLI write
  → checks → git/PR → guard/agents → admin/switch-over). "Deliver init first" isn't possible — `init`
  scaffolds a workspace the core must already be able to drive.
- **P11** unlocks client use. **P12 (Twenty) and P13 (extra commands)** follow, as you asked. **P14/P15**
  close the increment.

## ADR → phase (phase numbers live here, not in the ADRs)

| ADR | Phase(s) |
| --- | --- |
| ADR-001 packaging | P02 (workspace, dual tsconfig, `0.1.0-dev.0`); P10 (tarball + `spine-dev` at switch-over) |
| ADR-002 toolchain | P02 |
| ADR-003 CLI contract | P05 (envelope, exit table, renderer); P09 (separate guard bin) |
| ADR-004 schemas | P03 |
| ADR-005 documents | P03 (parser, index); P04 (derived `graph.json`) |
| ADR-006 event log & state | P04 |
| ADR-007 lifecycles & gates | P04 (tables, reducer); P08 (`phase_pr` detection) |
| ADR-008 context | P03 (index ranges); P05 (`context`); P06 (plan-time budget in `plan apply`) |
| ADR-009 git & PR | P08 |
| ADR-010 guard | P09 (bin + hook); P06 (`active.json` writer, test-hashes at Tests-ready) |
| ADR-011 checks & secrets | P07 |
| ADR-012 admin boundary & settings | P02 (baseline settings); P10 (`spine-admin` + switch-over settings) |
| ADR-013 profiles & init | P11 |
| ADR-014 Twenty | P12 |
| ADR-015 testing | all phases (layers); P02 (CI sandbox/network-denied); P14 (red-team) |
| ADR-016 switch-over | P10 |
| ADR-017 OS & preflight | P02 (preflight + `doctor`); P10 ("refuse if unprotected") |

## Schedule verdict (honest)

**Target 2026-12-13 is ~20 days; the Must core (P01–P11) is ≈ 189 h**, built largely by hand through the
bootstrap process while you also sell and deliver December work. **Plan on P01–P11 not all landing by the
13th.**

- **Firm by ~2 weeks:** P01–P06 (core + both CLI sides) — the part that must never be wrong.
- **Week-3 stretch:** P07–P11 (checks, git/PR, guard, admin/switch-over, init). `init` + profile green by
  the 13th is the tightest item.
- **After the 13th:** P12 Twenty, P13 extra commands, P14 quality, P15 delivery.

**The December client is not blocked on this.** Run it in **bootstrap mode** (this process) and fold the
spine in as phases land — see the parallel human track and the client bootstrap kit.

## Requirement coverage

| Requirement | Phases |
| --- | --- |
| REQ-001, REQ-002, REQ-003, REQ-004 | P11 (REQ-004 also P12) |
| REQ-005 | P13 |
| REQ-010, REQ-011, REQ-014, REQ-023, REQ-082 | P04 |
| REQ-012, REQ-013, REQ-035 | P10 |
| REQ-015 | P06 (split), P10 (cut) |
| REQ-016, REQ-032, REQ-033, REQ-060 | P06 |
| REQ-024, REQ-030, REQ-031, REQ-034 | P05 |
| REQ-020, REQ-021, REQ-022 | P03 |
| REQ-025, REQ-040, REQ-041 | P07 |
| REQ-042, REQ-043 | P08 |
| REQ-044 | P13, P15 |
| REQ-050, REQ-051, REQ-052 | P09 |
| REQ-061, REQ-062, REQ-063, REQ-064 | P13 |
| REQ-070, REQ-071 | P12 |
| REQ-080, REQ-081, REQ-083, REQ-084 | P02 |
| REQ-090 | P06 |
| REQ-091 | P09 |

## Human-applied settings — by phase (one place, so none are lost)

Agents can't edit `.claude/` or `spine.yaml`; **you** apply these. `.claude/settings.json` is write-protected,
so this table (not that file) is the source of truth; verify exact Claude Code keys against current docs
(ADR-012). Network rules govern **Bash only** (D2): `WebSearch` is allowed and `WebFetch` stays on `ask`,
MCP (incl. Context7) runs outside the sandbox, and the excluded `spine` makes its own `gh`/Twenty calls.

| When | Setting / action | Why | ADR / D |
| --- | --- | --- | --- |
| **Bootstrap (now)** | copy `design-reviewer` and the three `review-*` commands into `.claude/` | the architecture stage's independent reviews (ADR-018) run via these | 018 |
| **Machine setup (H0, `spine-admin setup` → `~/.claude/settings.json`, once per machine)** | `sandbox.failIfUnavailable: true`, `sandbox.allowUnsandboxedCommands: false` | Only honored from user/managed scope; must be present before P01 (`spine-admin init` exits 3 if absent) | 006, 012, D7 |
| Machine setup (H0) | `excludedCommands: ["spine *"]` | Ignored from workspace scope in admin-required mode; must be user-level | 006, 012, D7 |
| Machine setup (H0) | `strictAllowlist: true` (no `allowedDomains`) — **key path pending P01-T05 AC-4** (docs show both `sandbox.strictAllowlist` and `sandbox.network.strictAllowlist`); needs **CC ≥ v2.1.219** | Requires user/managed scope; agent Bash has no network (D2) | D2, 012, D7 |
| Machine setup (H0) | `sandbox.credentials` masks for token env vars | Requires user/managed scope | 011, 012, D7 |
| **Baseline (P02)** | `sandbox.enabled: true` | Enable the sandbox | 006, 012 |
| Baseline (P02) | `sandbox.network.allowedDomains: []` | Workspace-scope duplicate of machine-level strictAllowlist (documentation only; not relied on) | D2, 012, D7 |
| Baseline (P02) | `disableBypassPermissionsMode: "disable"`, `disableAutoMode: "disable"` | Close the mode-switch escape hatches | 012 |
| Baseline (P02) | allow `Bash(spine *)`, read-only `git` (status/diff/log/show), `WebSearch`; **allow `git add`/`commit`/`switch`** | Dispatcher commits one per task during bootstrap (D1); `WebSearch` for fact-checking | 009, 010, D1 |
| Baseline (P02) | ask `Bash(spine pr *)`, `WebFetch` | `spine pr` pushes/opens a PR; ask is evaluated before allow. **WebFetch stays on `ask`**; documentation-domain allow rules deferred to a decision after the stage review | 009, 012 |
| Baseline (P02) | deny `Bash(spine-admin *)`, `Bash(gh *)`, git push/merge/rebase/reset/checkout/clean/branch-D/tag | Human-only boundary; no `gh` reflex-approvals; spine owns history | 009, 012 |
| Baseline (P02) | deny **installs**: `pnpm add/remove/up/install/i/update/create`, `pnpm dlx`, `npx`, `npm`, `yarn`, `bunx`, `corepack` | `new_dependency` gate; a speedbump behind D2's no-network | 011, D6 |
| Baseline (P02) | deny `cat *.env*` / Read `.env*`, `security`, `secret-tool` | Keep secrets off the agent | 011 |
| Baseline (P02) | deny Edit/Write `.claude/**` · `~/.claude/**` · `spine.yaml` · **shell rc (`~/.zshrc`,`~/.zprofile`,`~/.bashrc`,`~/.bash_profile`,`~/.profile`)** | No tampering with rules, nor alias/PATH hijack of `spine` | 012, 014→ADR-017 |
| Baseline (P02) | `sandbox.filesystem.denyRead`: `.env*`, home creds (`~/.ssh`,`~/.aws`,`~/.config/gh`,`~/.npmrc`,`~/.netrc`,`~/.git-credentials`); `sandbox.credentials` entries (`mode: "deny"`; macOS: `mask`→`deny` fallback) mask token env vars | Secrets unreadable | 011, 012 |
| Baseline (P02) | `sandbox.filesystem.denyWrite` mirroring **every** Edit/Write deny (`.claude`,`~/.claude`,`CLAUDE.md`,`.mcp.json`,`spec.md`, shell rc) | Edit denies don't promise to stop Bash writes | 012 |
| Baseline (P02) | env `GIT_OPTIONAL_LOCKS=0` | Read-only `git status` won't write | 009 |
| **Switch-over (P10)** | `sandbox.filesystem.denyWrite` **add** `project/state/**`, `STATE.md`, `project/.git`, `code/.git`, `spine.yaml` | Only the spine writes state/git once it owns them | 006, 009, 012 |
| Switch-over (P10) | **deny `git add`/`commit`/`switch`** (moved from baseline) | After switch-over only the spine commits | D1, 009 |
| Switch-over (P10) | install global PreToolUse hook **`spine-guard \|\| exit 2`** (only now that `spine-guard` exists) | `\|\| exit 2` would brick every tool call if the binary were missing | 010, 012 |
| Switch-over (P10) | tag both repos; `spine-admin upgrade` (package templates + diff); restart Claude Code; run red-team | Reversible cutover; load new settings/hooks | 016, 015 |
| **Per client `init` (P11)** | add `code/CLAUDE.md`, `code/AGENTS.md` to the write-protected set | Stop planted standing instructions for later sessions | 013 |
| **Later / per project** | pin stdio MCP exact versions; add Vercel MCP (project-specific URL) only when hosting is decided | `@latest` = unreviewed local code; shared endpoint leaks other clients | 013 |
| Environment (WSL) | workspace on the Linux filesystem (`~/…`), WSL2, Claude Code in the WSL remote | `/mnt/c` breaks `chmod 0600`; native Windows runs unsandboxed | 017 |

## Parallel human track (not spine phases)

| # | Task | When | Why |
| --- | --- | --- | --- |
| H0 | **Apply user-level settings block** — until `spine-admin setup` ships, manually add the machine-level keys (`sandbox.failIfUnavailable: true`, `sandbox.allowUnsandboxedCommands: false`, `excludedCommands: ["spine *"]`, `sandbox.network.strictAllowlist: true`, `sandbox.credentials` masks) to `~/.claude/settings.json` | **Before P01** | These keys are ignored from workspace scope; `spine-admin init` exits 3 if any are absent; P01 probes assume the hardened config is in place |
| H1 | **Client bootstrap kit** — package this workspace's commands, agents and baseline settings (minus spine-specific docs) + the `nextjs-static` overlay as a **manual checklist**, same `STATE.md` format | Before the first December client starts | Lets a client run in bootstrap mode now; same format means ADR-016 import works for it later |
| H2 | **Install Twenty now**; use built-in Opportunities/Companies natively for December sales, with `taxonomy.json` stage names | Now | Real pipeline before `sync` (P12); no rework of categories later |
| H3 | **Bootstrap backup** — push `project/` by hand after each `/approve` (until `spine-admin` exists, then D4 automates it) | Now, every approval | `project/` is the only home of the event log |

## Risks and assumptions

| Risk or assumption | Effect if wrong | Mitigation |
| --- | --- | --- |
| Claude Code sandbox / `agent_type` / exit-2 / network-none behaviours differ from assumed | ADR-006/010/012 don't hold | **P01 spike proves them first**; re-plan on failure |
| The Must core (~189 h) won't fit by 2026-12-13 while selling/delivering | The spine is late for the first client | Reach the loop early; **run the client in bootstrap mode** (H1) meanwhile |
| Twenty 2.0 SDK can't express the model | P12 slips | **P12-opening half-day spike**; metadata-API fallback (ADR-014) |
| `@anthropic-ai/sandbox-runtime` (research preview) API shifts | Check runner breaks | Pin it; `new_dependency` gate; isolate behind the process adapter |
| Ubuntu 24.04 blocks bwrap (AppArmor userns) | Linux/WSL (tier 2) checks fail | P02 CI verifies bwrap on the runner; preflight detects + prints remediation |
| `project/` lost between backups | Event-log history gone | D4: `spine-admin` pushes after each approval (never forced); `doctor` warns on unpushed commits |

## Switch-over task

The switch-over (ADR-016) is the first task block of **P10**: once `status`, `next`, `submit` and
`approve` work, migrate the bootstrap docs, `spine-admin import --dry-run`, verify the normalized
projection matches `STATE.md`, apply the phase-2 settings + guard hook, restart, red-team, and archive
`STATE.md` as `STATE.bootstrap.md`. From then on the spine **renders** `STATE.md` as a write-protected view.
