# State: bootstrap mode

> Manual spine. Claude reads this file before every step and updates it after every step.
> Only the human passes gates, with `/approve` or `/reject`. Replaced by the spine's event log at
> the switch-over task.

## Now

| Field | Value |
| --- | --- |
| Project | spine |
| Increment | I01, Spine MVP |
| Stage | development |
| Current node | I01 development — **P01 In progress**; T01 scaffolding committed (8beedc6), T02 scaffolding authored (awaiting human review) |
| Status | ready |
| Attempt | 1 |
| Open gate | none |
| Frozen nodes | none |
| Next action | Human: review the **uncommitted** P01-T02 scaffolding in `probes/excluded/`; on OK I commit it and author **T03**. The hardened-session runs (S2/S2b, then P01-T01…T05) begin once the scaffolding set is ready. P01 is **records-only** — no phase branch, no tester (manual probes); the Tester→Coder→Verifier cycle resumes at P02; P01 exits via phase review + `/approve` (not `phase_pr`). |

## Stages of I01

| Stage | Status |
| --- | --- |
| discovery | done (2026-11-22) |
| architecture | done (2026-11-25) |
| development | in progress |
| quality | not started |
| delivery | not started |

## Phases

| Phase | Title | Status | Branch |
| --- | --- | --- | --- |
| P01 | Harness verification spike (6 probes) | **In progress** | none — records-only (exits via review + /approve) |
| P02 | Repo, toolchain, baseline hardened settings, CI | Planned |  |
| P03 | Schemas, parser, id index | Planned |  |
| P04 | Pure core: event log, reducer, transitions | Planned |  |
| P05 | CLI read side (status/next/context/session/doctor) | Planned |  |
| P06 | CLI write side (submit/plan apply/cr raise/active.json) | Planned |  |
| P07 | Checks & secrets | Planned |  |
| P08 | Git & PR | Planned |  |
| P09 | Guard & Claude assets | Planned |  |
| P10 | spine-admin + switch-over | Planned |  |
| P11 | init + nextjs-static | Planned |  |
| P12 | Twenty app + sync | Planned |  |
| P13 | Extra commands (increment/ticket/time/export/upgrade) | Planned |  |
| P14 | Quality: dogfood + red-team + full audit | Planned |  |
| P15 | Delivery: v0.1.0 release | Planned |  |

## Gates passed

| Date | Gate | Node | Result | Note |
| --- | --- | --- | --- | --- |
| 2026-11-22 | stage_exit | I01 discovery | approved | Discovery done in a Claude conversation, 18–22 Nov. Output: spec v0.4 (`SPEC`) |
| 2026-11-25 | stage_exit | I01 architecture | approved | Outputs: architecture.md v4, plan.md v5, security.md v7, conventions v2, 18 ADRs, P01 (phase + 6 tasks). Reviews (ADR-018 transition): topic reviews waived for T01–T17; ADR reviews for 006/009/010/011/012/018; full stage review — all findings have a Response, all decisions recorded. |
| 2026-11-25 | plan | I01 plan + P01 | approved | plan.md v5 (15 phases, coverage, settings table, parallel human track) + P01 phase.md v3 and its 6 task.md (T01–T06). P01 → Approved. |
| 2026-11-26 | plan | I01 plan + P01 | approved | Re-approval after the credentials-shape **correction** (plan.md v6, ADR-012 v7 — no decision change). P01 phase.md v4 + task amendments T01 v3 / T02 v3 / T04 v4 / T05 v6 folded in. `stage_exit` not reopened (correction rule, ADR-018 v4). |

## Log

- 2026-11-22: Workspace bootstrapped from spec v0.4. Discovery closed; architecture ready to start.
- 2026-11-22: Architecture session S01 opened. Working the 17-topic agenda from the brief; Topic 1 (packaging) under discussion.
- 2026-11-22: Architecture session S01 closed. 17 topics decided (ADR-001…ADR-017); `architecture.md`, `plan.md` and P01 (phase + 5 tasks) written; `security.md` & `conventions.md` bumped to v2. Open gate: **stage_exit + plan**.
- 2026-11-24: Pre-gate review pass — applied 32 findings + 6 decisions (D1–D6). Plan split to **15 phases** (v2; ADR→phase table, settings table, parallel human track); `security.md` v3, `requirements.md` v2, `architecture.md` v2; `spec-errata.md` added; **all 17 ADRs amended** (phase numbers removed; ADR-006/009/010/011/012/015/017 → internal); P01 spike expanded to **6 probes**. Gate unchanged: **stage_exit + plan**.
- 2026-11-24: Decision — **independent design reviews** for the architecture stage (**ADR-018**, REQ-090/091). Wired into `code/claude/` architect + `/architecture`, `requirements.md` v3, `plan.md` v3; ADR-013/016 → internal. Reviews are now a `stage_exit` prerequisite (spine = all three) and have **not** been run. Gate unchanged: **stage_exit + plan**.
- 2026-11-24: ADR-018 **Transition (I01)** recorded (ADR-018 v2) — topic reviews **waived for T01–T17**; **adr reviews for ADR-018 + 006/009/010/011/012**; **stage review in full**; `stage_exit` is review-complete once those run with every finding's Response + decisions recorded. Also set ADR-001/002/003/004/005/007/008/014 → internal: **every spine ADR (001–018) is now internal**.
- 2026-11-24: **Reconciliation (S01 T6 `actor` detail)** — session log S01:71 (write-once record) says `actor` "set by spine from shell detection, never a flag." ADR-006 (amended 2026-11-23) now says "set by the writing binary, not by detection or a flag." The ADR text is correct; the S01 record is superseded on this point by ADR-012 (shell/env detection is not a boundary). No change to ADR-006.
- 2026-11-24: **ADR-018 adr review** complete (`reviews/ADR-018.review.md`, closed) — 6 findings, none rejected; fixes to architecture.md v3, ADR-018 v3, ADR-010 v3, requirements.md; human decision → guard denies `design-reviewer` reading `topics/*.architect.md` (all modes). **Remaining for review-complete `stage_exit`:** adr reviews of 006/009/010/011/012 + the stage review.
- 2026-11-24: **ADR-006 adr review** complete (`reviews/ADR-006.review.md`, closed) — 3 findings; F1 fixed (STATE.md reconciliation note), F2 fixed (ADR-005 v4 amendment), F3 rejected (REQ-023 stays minimum floor; SEC-012 is binding). No human decisions needed. **Remaining for review-complete `stage_exit`:** adr reviews of 009/010/011/012 + the stage review.
- 2026-11-24: **Reconciliation (S01 T9 branch protection)** — session log S01:114 says `spine init` "disables squash/rebase merges and sets merge-commit-only + branch protection" unconditionally. ADR-009's 2026-11-23 amendment supersedes this: branch protection is conditional on the GitHub plan (Free private repos get none). The ADR text is correct; the S01 record is superseded on this point.
- 2026-11-24: **ADR-009 adr review** complete (`reviews/ADR-009.review.md`, closed) — 4 findings, none rejected; F1 fixed (ADR-009 v3: PR body via `--body-file` added to Decision, REQ-043 now has design owner), F2 fixed (SEC-016 added to refs), F3 fixed (reconciliation note above), F4 fixed (Consequences separates `spine init` code from human-applied settings). No human decisions needed. **Remaining for review-complete `stage_exit`:** adr reviews of 010/011/012 + the stage review.
- 2026-11-24: **ADR-010 adr review** complete (`reviews/ADR-010.review.md`, closed) — 5 findings, none rejected; F1+F5 fixed (ADR-010 v4: unified deny rule — absent or mismatched `agent_type` while scoped role active = denied; CC #90662 named), F2 fixed (60 s timeout → 600 s default / 30 s), F3 fixed (disableAllHooks CLI flag route blocked by Bash allowlist; stated explicitly), F4 fixed (P01-T04 v2: AC-4 probes CC #90662 consistency; AC-5 probes hook sandbox status). No human decisions needed. **Remaining for review-complete `stage_exit`:** adr reviews of 011/012 + the stage review.
- 2026-11-24: **Reconciliation (S01 T11 phase number)** — session log S01:117 says sandbox-runtime `new_dependency` gate is in "P06". ADR-011 names no phase (correct per convention). The current plan (I01-PLAN) places ADR-011 in P07. S01:117's "P06" is superseded by the plan.
- 2026-11-24: **ADR-011 adr review** complete (`reviews/ADR-011.review.md`, closed) — 4 findings, none rejected; F1 fixed (ADR-011 v3: keychain test → P07 release blocker; Mach service dependency named; fallback stated), F2 fixed (STATE.md reconciliation note above), F3 fixed (security.md v4 SEC-006 adds post-check sweep; requirements.md v4 REQ-041 acceptance updated), F4 fixed (ADR-011 v3: Limitation bullet in Consequences). No human decisions needed. **Remaining for review-complete `stage_exit`:** adr review of 012 + the stage review.
- 2026-11-24: **WebSearch + web/docs tools** — added `WebSearch` to the workspace `settings.json` allow list; **ADR-010 v5** now lists `WebFetch`, `WebSearch` and the Context7 tools (`mcp__context7__*`) explicitly in the main-session, architect and design-reviewer guard policies; plan.md settings table + network note updated. Gate unchanged: **stage_exit + plan**.
- 2026-11-24: **Settings correction follow-ups** — (1) **ADR-012 v4** + plan H0 row mark the `strictAllowlist` key path **pending P01-T05 AC-4** (docs show `sandbox.strictAllowlist` vs `sandbox.network.strictAllowlist`) and note the **CC ≥ v2.1.219** requirement; **P01-T05 v3** adds AC-4 (resolve key path + version). (2) `WebFetch` kept on `ask`; documentation-domain allow rules deferred to a post-stage-review decision (noted in plan). No re-review of ADR-010 (the stage review covers it). Gate unchanged: **stage_exit + plan**.
- 2026-11-24: **ADR-012 adr review** complete (`reviews/ADR-012.review.md`, closed) — 4 findings; F1+F2 (blockers — settings scope) resolved by **D7** (two-tier split: machine-level keys to `~/.claude/settings.json` via new `spine-admin setup`; workspace retains project-scoped keys; `spine-admin init`/`spine doctor` exit 3 if machine-level block absent; H0 added to H-track); F3 fixed (sandbox.network: none → correct key structure); F4 fixed (fully-qualified key paths in plan.md). Files updated: ADR-012 v3, plan.md v3 (settings table + H0), security.md v5 SEC-007, P01-T05 v2 AC-3. **Remaining for review-complete `stage_exit`:** the stage review.
- 2026-11-24: **Stage review** complete (`reviews/architecture.review.md`, status open) — **1 blocker + 3 major + 3 minor, all confirmed & fixed**, none rejected. 12 bypass attempts all held. Fixes (all key facts re-verified against live CC docs): **F1** (blocker) the exclusion key is **`sandbox.excludedCommands`** (nested; top-level ignored) — corrected everywhere; **F2** network allowlist resolved to **`sandbox.network.strictAllowlist`** (needs CC ≥ v2.1.219), "pending both paths" retired; **F3** `sandbox.credentials` → **`mode: "deny"`** (masking inoperative under no-network / macOS) and moved to the workspace tier; **F4** stale P01 phase numbers (guard P09, admin P10, checks P07); **F5** CC #90662 re-worded (auto-closed not-planned, not won't-fix); **F6** `cr raise` (+ `setup`) added to the container table; **F7** P01-T04 AC-3 network key. Files: security.md v6, ADR-006 v3, ADR-010 v6, ADR-012 v5, architecture.md v4, plan.md v4, phase.md v3, P01-T01 v2 / T02 v2 / T03 v2 / T04 v3 / T05 v4. **No human decision strictly required; F3 flagged for confirmation (touches D7 "masks").** All three review types (topic waived; adr ×6; stage) now done → `stage_exit` is **review-complete**, pending the human's acknowledgement + `/approve`.
- 2026-11-25: **Stage-review decisions recorded** (`reviews/architecture.review.md` → **closed**). **F3 confirmed** — `sandbox.credentials` use `mode: "deny"` in the workspace tier, no masking now or later; check secrets inject via spine's `@anthropic-ai/sandbox-runtime` (ADR-011), not CC's sandbox. Two corrections the human raised from the CC settings reference: (a) **D7 rationale** reworded — the three machine-level keys (`sandbox.excludedCommands`/`allowUnsandboxedCommands`/`failIfUnavailable`) have scope **"Any file"** and stay at user level for **precedence + coverage** (user-level `false` beats project `true`; one file covers every workspace), not because workspace is ignored; only `strictAllowlist` (+ masking, unused) is truly user/managed-only; **no placement change**. (b) **`disableAutoMode`** is a **top-level** key; `permissions.disableBypassPermissionsMode` stays under `permissions`; **P01-T05** gains a `claude doctor` acceptance check (AC-5). Files: ADR-012 **v6**, security.md **v7**, plan.md **v5**, P01-T05 **v5**. Gate: **stage_exit + plan** now review-complete and ready for `/approve`.
- 2026-11-25: **`/approve stage_exit`** (I01 architecture). Architecture stage **exits → development** begins. The **`plan`** gate remains open (approved separately). Next: human `/approve` the plan gate, then the Tester starts P01-T01.
- 2026-11-25: **`/approve plan`** (I01 plan + P01). P01 → **Approved**; Phases table populated (P01 Approved, P02–P15 Planned). No gate open. Next: run **P01-T01**, the first harness probe (manual, real CC session under the full switch-over settings); record results through P01-T06's go/no-go before P02.
- 2026-11-26: **P01-T01 scaffolding committed** (8beedc6, by human). **P01-T02 scaffolding authored** (`probes/excluded/`: fixture `Bash(spine-admin *)` deny + denyWrite on `state/`; stub `spine`/`spine-admin` in a probe-only `bin/`; README with the two-run AC-2/AC-3 split), uncommitted for review. Next: human reviews T02 → I commit it + author T03.
- 2026-11-26: **`/approve plan`** (I01 plan + P01, re-approval). Plan gate closed; plan.md v6 + P01 phase/tasks blessed. No gate open. Next: human reviews the uncommitted P01-T01 scaffolding → I commit it + author T02; then S2/S2b + run P01-T01.
- 2026-11-26: **Post-gate corrections rule** (human directive). Recorded in **ADR-018 v4** (amend line) and **conventions.md v3**: after `stage_exit`, an ADR edit that corrects a fact/key path/shape/wording **without changing a decision** is a *correction* — amend line + STATE log line, **no gate reopened**; corrections are re-checked together by `/review-adr` at the phase's review; an edit that changes a *decision* needs a CR (→ its own adr review). Applying this, **`stage_exit` is NOT reopened** for ADR-012 v7 (the prior "human to decide" note is resolved: it's a correction). The **plan gate stays open** for `/approve plan` (plan.md v6). ADR-012 v7 will be re-checked at P01's phase review alongside anything T01–T05 bring.
- 2026-11-26: **Credentials-shape correction** (human directive). Pinned the exact `sandbox.credentials` entry shape from the CC sandboxing docs — `envVars` `{ "name", "mode": "deny" }`, `files` `{ "path", "mode": "deny" }` (paths per `sandbox.filesystem` prefix rules) — in **ADR-012 v7**, **plan.md v6**, and the **T01 fixture** (now clean loadable JSON, real home path, no comment keys; the "best-guess" note dropped). Committed ADR-012 + plan.md + STATE on `project/` `main`; the T01 scaffolding stays **uncommitted** pending human review. plan.md changed → **plan gate reopened** (ADR-007); the ADR-012 change also lapses **stage_exit** — human to decide whether to re-approve it. Next: `/approve plan`, then review the scaffolding.
- 2026-11-26: **P01 run-decisions folded in** (human directives). **phase.md v4:** P01 is records-only — **no phase branch / no `phase_pr`** (ADR-009 single `main`); exits via phase review + `/approve`; stub cleanup added to Exit criteria. Task amendments: **T01 v3** (Edit/Write blocked by an `Edit`/`Write` permission deny, not `denyWrite`; credentials use `credentials.envVars`/`files`), **T02 v3** (spine-admin probed twice — prefix form → permission-layer refusal, full path → `denyWrite` OS boundary; stubs in a probe-only PATH dir), **T04 v4** (AC-5 hook now **writes** into the `denyWrite` state/ dir to prove hooks are unsandboxed), **T05 v6** (PATH-shadow is the required test; alias optional + restore `~/.zshrc`). H0 being applied permanently to `~/.claude/settings.json` (D2/D7); `dev` to be created by the human in `code/` for P02. Committed on `project/` `main`. Next: build throwaway workspace + `claude doctor` (S2/S2b), then run P01-T01.
