---
id: P01-findings
type: findings
parent: P01
increment: I01
stage: development
status: draft
version: 1
refs: [SECURITY, ADR-006, ADR-009, ADR-010, ADR-011, ADR-012, ADR-017]
visibility: internal
author: architect
updated: 2026-11-26
---

# P01 harness spike — findings & go/no-go

> Skeleton. Fill each **Result** (pass / fail) and **Evidence** after running the probes. T06-AC-1
> needs the CC version on every probe; T06-AC-2 needs the explicit go/no-go + any CR.
>
> **Evidence** = per-session `/export` transcript(s) (`<probe>-session<n>.txt`) plus the named log/state
> files, all under `probes/<name>/output/` (see `probes/OPERATOR-SHEET.md`).

| Field | Value |
| --- | --- |
| Claude Code version | `______` (expected 2.1.325; `claude --version`) |
| Platform / tier | macOS arm64 — tier 1 |
| Where run | throwaway workspace `~/spine-harness-probe/` under the switch-over settings |
| Settings-validating command | `______` (record: CLI `claude doctor` vs in-session `/doctor` — see T05) |

## T01 — denyWrite · Edit-deny · denyRead · credentials  (ADR-006, ADR-012)
| AC | Expected | Result | Evidence (probes/denywrite/output/) |
| --- | --- | --- | --- |
| AC-1 | Bash append to `state/` blocked; file unchanged |  |  |
| AC-2 | Edit **and** Write to `state/**` blocked by `Edit(./state/**)` |  |  |
| AC-3 | nested `.env` read (cat/node) blocked by `denyRead` |  |  |
| AC-4 | `PROBE_TOKEN` hidden (`credentials.envVars` deny) |  |  |
| failIfUnavailable | **not testable on macOS tier 1** — covered by docs + `doctor` key recognition | n/a |  |

## T02 — excludedCommands asymmetry  (ADR-012)
| AC | Expected | Result | Evidence (probes/excluded/output/) |
| --- | --- | --- | --- |
| AC-1 | excluded `spine` writes `state/` (unsandboxed) |  |  |
| AC-2 | `spine-admin` (prefix) → permission refusal (not OS boundary) |  |  |
| AC-3 | full-path `spine-admin` → `denyWrite` block (OS boundary) |  |  |

## T03 — PreToolUse exit codes  (ADR-010)
| AC | Expected | Result | Evidence (probes/exit2/output/) |
| --- | --- | --- | --- |
| AC-1 | exit 2 blocks the marker Bash call |  |  |
| AC-2 | exit 1 (any non-2) does **not** block |  |  |
| AC-3 | `spine-guard \|\| exit 2`, guard missing/crashing → blocked (fail closed) |  |  |

## T04 — agent_type · network · unsandboxed hook  (ADR-010)
| AC | Expected | Result | Evidence (probes/agent-type/output/) |
| --- | --- | --- | --- |
| AC-1 | subagent firings carry `agent_type` |  |  |
| AC-2 | main-session firing has no `agent_type` / sentinel |  |  |
| AC-3 | network Bash call denied, **no** per-domain prompt |  |  |
| AC-4 | same `agent_type` across ≥3 firings (CC #90662 absent) |  |  |
| AC-5 | hook writes into `denyWrite` dir (hooks unsandboxed) |  |  |

Exact `agent_type` field name + observed values: `______`

## T05 — resolution + settings keys  (ADR-012, ADR-017, SEC-020)
| AC | Expected | Result | Evidence (probes/resolution/output/) |
| --- | --- | --- | --- |
| AC-1 | PATH-placed `spine` run unsandboxed? (shadow risk recorded; **alias = known residual**, mitigated by rc-file denies + preflight) |  |  |
| AC-2 | every settings key recognised; no unknown-setting warning |  |  |
| AC-3 | scope matrix recorded (user scope for the four H0 keys) |  |  |
| AC-4 | `strictAllowlist` effective; version ≥ v2.1.219 |  |  |
| AC-5 | `claude doctor` / `/doctor` report no rejected/unknown entries |  |  |

## Surprises / deviations
- (exact field names, exit codes, messages, unknown keys, scope behaviours)

## Go / no-go  (T06-AC-2)
**Verdict:** `______`  (GO = all probes green → P02 may start · NO-GO → CR before P02)

If NO-GO, name the affected ADR(s) and raise a CR that re-plans them before P02:

| Affected ADR | Probe / AC | What failed | CR id |
| --- | --- | --- | --- |
|  |  |  |  |
