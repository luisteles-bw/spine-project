# P01-T04 — PreToolUse input carries `agent_type`; network-deny; unsandboxed hook

Proves the inputs ADR-010's guard relies on: the PreToolUse hook input carries an **`agent_type`** for
subagent calls (absent/sentinel for the main session), consistently across a run; agent Bash has **no
network** under `allowedDomains: []` + `strictAllowlist: true` (no per-domain prompt); and the hook runs
**unsandboxed**.

> Reuses the T01 throwaway workspace; runs in the hardened session (cwd `~/spine-harness-probe`).

## Setup (human, once)
1. Install the hook: `mkdir -p ~/spine-harness-probe/hooks && cp log-hook.sh ~/spine-harness-probe/hooks/ && chmod +x ~/spine-harness-probe/hooks/log-hook.sh`
2. Fresh log: `: > ~/spine-harness-probe/hooks/agent-type.log`
3. Confirm H0 has `sandbox.network.strictAllowlist: true` (user scope); merge `fixture.settings.json`
   here into `~/spine-harness-probe/.claude/settings.json` (`denyWrite` on `state/`, `allowedDomains: []`,
   the PreToolUse `Bash` hook). Run `claude doctor` (S2b).
4. `cd ~/spine-harness-probe && claude` — note `claude --version`.

## Run (inside the hardened session)
- **AC-2 (main session)** — make one Bash call from the main session, e.g. `echo main-session-call`.
- **AC-1 / AC-4 (subagent)** — dispatch a subagent that makes **≥3 separate Bash calls**, e.g. prompt:
  *"Dispatch a general-purpose subagent that runs three separate Bash commands: `echo one`, then
  `echo two`, then `echo three`."*
- **AC-3 (network)** — make a Bash call that needs the network, e.g.
  `curl -sS https://example.com` (or `node -e "fetch('https://example.com').then(()=>0)"`).
- **AC-5 (unsandboxed hook)** — after the above, check `~/spine-harness-probe/state/hook-unsandboxed.txt`
  and the `_probe_hook_write` markers in the log.

## Inspect
`cat ~/spine-harness-probe/hooks/agent-type.log` — one JSON line per firing (+ a `_probe_hook_write`
marker line after each). Look at `agent_type` per line, and compare main-session vs subagent firings.

## Pass / fail
| AC | PASS |
| --- | --- |
| AC-1 | subagent firings carry an `agent_type` identifying the subagent |
| AC-2 | the main-session firing has **no** `agent_type` (or a documented sentinel) |
| AC-3 | the network Bash call is **denied with no interactive per-domain prompt** |
| AC-4 | all **three** subagent firings carry the **same** `agent_type` (CC #90662 absent on this version) |
| AC-5 | `hook-unsandboxed.txt` exists / markers read `ok` — the hook wrote into the `denyWrite` dir |

Record the CC version and the exact `agent_type` field name + values. A FAIL (no/intermittent
`agent_type`, a network prompt instead of a denial, or a sandboxed hook) → red probe; name **ADR-010**
for the T06 go/no-go. Paste the log + raw output into `./output/`.

## Notes
- The matcher is the tool name `Bash`; both the main session and the subagent make Bash calls so their
  firings are directly comparable in one log.
- `strictAllowlist: true` is the H0 user-scope key; `allowedDomains: []` here is the workspace duplicate
  (documentation only). Together agent Bash has no network (D2).
- Hook `command` paths are absolute (fine for hooks, unlike permission-rule paths).
- Cleanup after T06: remove the probe hook from settings; delete `~/spine-harness-probe/hooks` and
  `state/hook-unsandboxed.txt`.
