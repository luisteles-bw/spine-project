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
| Claude Code version | **2.1.325** — confirmed (T01 & T02 session banners + each probe's `version.txt`) |
| Platform / tier | macOS arm64 — tier 1 |
| Where run | throwaway workspace `~/spine-harness-probe/` under the switch-over settings |
| Settings-validating command | `______` (record: CLI `claude doctor` vs in-session `/doctor` — see T05) |

## T01 — denyWrite · Edit-deny · denyRead · credentials  (ADR-006, ADR-012)
| AC | Expected | Result | Evidence (probes/denywrite/output/) |
| --- | --- | --- | --- |
| AC-1 | Bash append to `state/` blocked; file unchanged | **PASS** | `denywrite-session1.txt` — "Operation not permitted", `append exit=1`, lines before=1 after=1; `state-after.txt` / `state-listing.txt` unchanged |
| AC-2 | Edit **and** Write to `state/**` blocked by `Edit(./state/**)` | **PASS** | session1 Edit + Write both "denied by your permission settings"; session2 Read(`seed`)→Edit refused; no `probe2.txt` on disk |
| AC-3 | nested `.env` read (cat/node) blocked by `denyRead` | **PASS** | `denywrite-session1.txt` — `cat` + `node` both EPERM, exit 1 |
| AC-4 | `PROBE_TOKEN` hidden (`credentials.envVars` deny) | **PASS** | `[<unset>]` in sessions 1 & 2; `token-control.txt` shows it set in the launching shell |
| failIfUnavailable | **not testable on macOS tier 1** — covered by docs + `doctor` key recognition | n/a | per T01 v5 AC-2 |

> **T01 verdict: PASS** — record `T01-denywrite-blocks-append/a1.verify.md` (+ `a1.checks.json`, 14 cross-checks). Sessions ran under auto mode — see Surprises F-1 (AC-independent here).

## T02 — excludedCommands asymmetry  (ADR-012)
| AC | Expected | Result | Evidence (probes/excluded/output/) |
| --- | --- | --- | --- |
| AC-1 | excluded `spine` writes `state/` (unsandboxed) | **PASS** | `state-after-session1.txt` — one `spine wrote…` line (probe.txt 31 B); `resolution.txt` = stub first on PATH |
| AC-2 | `spine-admin` (prefix) → permission refusal (not OS boundary) | **PASS** | `excluded-session1.txt` — "…has been denied"; no `spine-admin` line in state |
| AC-3 | full-path `spine-admin` → `denyWrite` block (OS boundary) | **PASS\*** | `excluded-session2.txt` — "Operation not permitted", exit 1; `state-after-session2.txt` byte-identical to session1. **\*** OS boundary reached via a `bash`-wrapper + `--permission-mode default` relaunch; the session-1 full-path spelling was itself caught by the `Bash(spine-admin *)` deny (see Surprises F-2/F-3) |

> **T02 verdict: PASS** — record `T02-excluded-vs-nonexcluded-write/a1.verify.md` (+ `a1.checks.json`).

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
- **F-1 — Probes ran under auto mode (config gap, cross-cuts T01 & T02).** Neither the T01/T02 fixtures nor the live H0 `~/.claude/settings.json` set `disableAutoMode` (top-level) or `permissions.disableBypassPermissionsMode`, both of which the switch-over design requires (ADR-012). So "ask" permissions were auto-approved. The AC verdicts hold — `excludedCommands`, explicit `deny` rules and sandbox `denyWrite`/`denyRead` all fire independent of auto mode — but the **permission-prompt posture was not exercised**. **Action before T03–T05:** add `disableAutoMode: "disable"` and `permissions.disableBypassPermissionsMode: "disable"` to H0 (the CC permissions docs use the string `"disable"`, not a boolean) so the remaining probes run the real hardened config; relevant to T05 AC-2/AC-3/AC-5 (key recognition + scope; AC-5 confirms the value form via `doctor`).
- **F-2 — T02 AC-3 premise corrected (applied; one open question).** AC-3 (task.md **v4** + README) now reads: an invocation the `Bash(spine-admin *)` deny doesn't match (e.g. `bash <path>/spine-admin`) still has its write blocked by `denyWrite`. The session-2 bypass came from the **`bash <path>` spelling** not matching the deny, **not** from a weaker permission mode — session 2 ran `--permission-mode default`, session 1 ran auto mode. **Open question:** session 1's refusal of the *bare* full path (`~/…/bin/spine-admin probe-write`, no `bash`) happened under auto mode, so we can't yet tell whether the `Bash(spine-admin *)` rule matched it or the auto-mode classifier refused it. A **T05 operator-sheet prompt** (run in `--permission-mode default`) resolves it — refused with no prompt → the rule matched; a prompt appears or it runs → it was auto mode. **Update this finding with the T05 answer.**
- **F-3 — Deny bypass → "the sandbox is the wall" (T02, confirms ADR-012).** In session 2 a `bash <fullpath>` invocation under `--permission-mode default` evaded the `Bash(spine-admin *)` deny and ran, yet sandbox `denyWrite` still returned EPERM and nothing was written (state byte-identical to session 1). Defense-in-depth validated: Bash permission prefix rules are a speedbump; the OS sandbox is the real admin boundary.
- **F-4 — Probe stub bug, fixed this session (T02).** `probes/excluded/bin/spine` and `bin/spine-admin` printed "appended" and exited 0 even on a failed write (`$?` captured the `echo`, not the `>>` redirect). Did not affect the verdict (writes judged from state files). **Fixed:** both stubs now print "appended (exit 0)" only on a successful write and otherwise report the failure to stderr and exit non-zero (success-path + failure-path both re-tested).
- (T03–T05: field names, exit codes, messages, unknown keys, scope behaviours — to come.)

## Go / no-go  (T06-AC-2)
**Verdict:** `______`  (GO = all probes green → P02 may start · NO-GO → CR before P02)

If NO-GO, name the affected ADR(s) and raise a CR that re-plans them before P02:

| Affected ADR | Probe / AC | What failed | CR id |
| --- | --- | --- | --- |
|  |  |  |  |
