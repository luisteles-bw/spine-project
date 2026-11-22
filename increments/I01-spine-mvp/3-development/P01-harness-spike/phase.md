---
id: P01
type: phase
title: Harness verification spike
increment: I01
stage: development
parent: I01-PLAN
status: draft
version: 1
refs: [SECURITY, ADR-006, ADR-009, ADR-010, ADR-012]
branch: phase/P01-harness-spike
billing: none
estimate_h: 4
visibility: internal
author: architect
updated: 2026-11-22
---

## Goal

Prove, in a real Claude Code session on macOS (tier 1), the four harness behaviours the spine's
security model rests on — **before** any of it is built. If a probe fails, the affected ADRs are
re-planned (via CR) before P02 starts, so nothing is built on a false assumption.

## Scope
- In: throwaway **fixture** `settings.json`, small probe scripts and stub binaries, and a findings
  record with a go/no-go.
- Out: any spine or product code (P02+); changing the real workspace `settings.json`; Linux/WSL
  verification (tier 2, deferred).

## Tasks
| Task | Title | Size | Est. h | Depends on |
| --- | --- | --- | --- | --- |
| P01-T01 | Sandbox `denyWrite` blocks a Bash append | S | 1 | none |
| P01-T02 | `excludedCommands` — excluded writes, non-excluded blocked | S | 1 | P01-T01 |
| P01-T03 | PreToolUse **exit 2** blocks (exit 1 does not) | S | 0.5 | none |
| P01-T04 | Hook input carries **`agent_type`** for subagents | S | 0.5 | none |
| P01-T05 | Findings record + go/no-go | S | 1 | P01-T01..T04 |

## Exit criteria
- [ ] All tasks Done, every manual criterion observed and recorded
- [ ] `review.md` passed (checks and security)
- [ ] Findings record states the Claude Code version and a clear **go/no-go**
- [ ] If any probe failed, a CR re-planning the affected ADR(s) is raised before P02
