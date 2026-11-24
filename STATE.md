# State: bootstrap mode

> Manual spine. Claude reads this file before every step and updates it after every step.
> Only the human passes gates, with `/approve` or `/reject`. Replaced by the spine's event log at
> the switch-over task.

## Now

| Field | Value |
| --- | --- |
| Project | spine |
| Increment | I01, Spine MVP |
| Stage | architecture |
| Current node | I01 architecture stage — outputs written, gate open |
| Status | awaiting approval |
| Attempt | none |
| Open gate | **stage_exit** (I01 architecture) + **plan** (plan.md, P01 phase.md + 5 tasks) |
| Frozen nodes | none |
| Next action | **Human:** review the architecture outputs, then `/approve` the `stage_exit` + `plan` gates, or `/reject <reason>`. Review list is in the session hand-off below. |

## Stages of I01

| Stage | Status |
| --- | --- |
| discovery | done (2026-11-22) |
| architecture | in progress |
| development | not started |
| quality | not started |
| delivery | not started |

## Phases

| Phase | Title | Status | Branch |
| --- | --- | --- | --- |
| none yet | Written by the Architect in `2-architecture/plan.md` |  |  |

## Gates passed

| Date | Gate | Node | Result | Note |
| --- | --- | --- | --- | --- |
| 2026-11-22 | stage_exit | I01 discovery | approved | Discovery done in a Claude conversation, 18–22 Nov. Output: spec v0.4 (`SPEC`) |

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
