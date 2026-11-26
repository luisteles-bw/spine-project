---
id: P01
type: phase
title: Harness verification spike
increment: I01
stage: development
parent: I01-PLAN
status: draft
version: 4
refs: [SECURITY, ADR-006, ADR-009, ADR-010, ADR-011, ADR-012, ADR-017]
branch: none
billing: none
estimate_h: 6
visibility: internal
author: architect
updated: 2026-11-26
---

## Goal

Prove, in a real Claude Code session on macOS (tier 1), the harness behaviours the spine's security
model rests on — **before** any of it is built. Run the probes in a **throwaway workspace** wired with
the **full switch-over settings** (not today's bootstrap settings), so we test the hardened config we
will actually ship. If a probe fails, the affected ADR(s) are re-planned (via CR) before P02 starts.

## Scope
- In: a throwaway workspace with the **full switch-over `settings.json`**; small probe scripts and stub
  binaries (`spine`, `spine-admin`, a guard); a findings record with a go/no-go.
- Out: any spine or product code (later phases); changing the real workspace `settings.json`; full
  Linux/WSL verification (tier 2 — note the bwrap/userns check, defer).

## Tasks
| Task | Title | Size | Est. h | Depends on |
| --- | --- | --- | --- | --- |
| P01-T01 | `denyWrite` blocks a Bash append; nested `.env` read + `sandbox.credentials` deny | S | 1 | none |
| P01-T02 | `sandbox.excludedCommands`: excluded `spine` writes, non-excluded `spine-admin` blocked | S | 1 | P01-T01 |
| P01-T03 | PreToolUse **exit 2** blocks (exit 1 doesn't); missing guard behind `\|\| exit 2` blocks | S | 1 | none |
| P01-T04 | Hook input carries **`agent_type`**; `sandbox.network.strictAllowlist` deny behaviour | S | 1 | none |
| P01-T05 | `spine` resolution (alias / PATH shadow) + every settings key exists in the installed CC | S | 1 | none |
| P01-T06 | Findings record + go/no-go | S | 1 | P01-T01..T05 |

## Exit criteria
- [ ] All tasks Done, every manual criterion observed in a throwaway workspace under the **full
      switch-over settings**, and recorded
- [ ] `review.md` passed (checks and security)
- [ ] Findings record states the Claude Code version and a clear **go/no-go**
- [ ] If any probe failed, a CR re-planning the affected ADR(s) is raised before P02
- [ ] Probe cleanup done: stub `spine`/`spine-admin` removed and the probe-only PATH dir cleared,
      `~/.zshrc` restored if the alias case was tested, throwaway workspace deleted (H0
      `excludedCommands: ["spine *"]` is machine-wide, so no stub `spine` may linger on `PATH`)

## Exit mechanism (P01-only exception)
P01 produces **records only** (probe scaffolding, captures, findings) — no code and no `code/` branch.
Per ADR-009 `project/` is a single `main` with one commit per transition, so P01 has **no phase branch
and no `phase_pr` gate**: it exits through the **phase review** (checks + security over the records)
and then the human's **`/approve`**. The `phase_pr` flow and the Tester→Coder→Verifier task cycle
resume at P02, which branches in `code/` from `dev`.
