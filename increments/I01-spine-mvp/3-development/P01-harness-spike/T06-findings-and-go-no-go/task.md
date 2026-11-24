---
id: P01-T06
type: task
title: Findings record and go/no-go
increment: I01
stage: development
parent: P01
status: planned
version: 1
refs: [SECURITY, ADR-006, ADR-009, ADR-010, ADR-012, ADR-017]
scope:
  touch: ["project/increments/I01-spine-mvp/3-development/P01-harness-spike/findings.md"]
  forbid: [".claude/**", "spine.yaml"]
size: S
estimate_h: 1
tdd: false
criteria:
  - { id: AC-1, check: manual, text: "A findings record lists each probe (T01–T05), the observed result, and the Claude Code version it was observed on" }
  - { id: AC-2, check: manual, text: "A clear go/no-go is recorded: if any probe failed, the affected ADR(s) (006/009/010/011/012/017) are named and a CR is raised to re-plan them before P02 starts" }
billing: none
visibility: internal
author: architect
updated: 2026-11-24
---

## Goal
Turn the probes into one reviewable record with an explicit go/no-go, so P02 only begins on a verified
foundation.

## Context
This is the gate on the whole security model (ADR-006/009/010/011/012/017). A green record lets P02
proceed; any red probe routes to a CR that re-plans the affected ADR before building.

## Steps
1. Collect the T01–T05 results and the Claude Code version into `findings.md`.
2. For each probe, state pass/fail and any surprises (exact field names, exit codes, messages, unknown keys).
3. Record the go/no-go. On any fail, name the affected ADR(s) and raise a CR.

## Out of scope
- Fixing a failed behaviour (that is a re-plan / CR, not this task).
- Documenting Linux/WSL (tier 2).
