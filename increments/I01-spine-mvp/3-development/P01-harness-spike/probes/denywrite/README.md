# P01-T01 — denyWrite blocks a Bash append (probe runbook)

Proves the assumptions under ADR-006 / ADR-012: sandbox `denyWrite` / `denyRead` stop Bash
writes/reads; an `Edit`/`Write` **permission deny** (not `denyWrite`) stops the Edit/Write tools;
`sandbox.credentials.envVars` with `mode: "deny"` hides a token from a sandboxed probe; and
`failIfUnavailable: true` makes a missing sandbox fail rather than run unsandboxed.

> This runs in a **throwaway** workspace under the full switch-over settings — never the real one.

## Setup (human, once)
1. Build `~/spine-harness-probe/.claude/settings.json` (S2) from plan.md's baseline + switch-over rows,
   paths swapped, merged with `fixture.settings.json` here. The fixture is clean, loadable JSON with the
   real home path baked in — use it as-is. Then run `claude doctor` (S2b) and fix any rejected/unknown
   key before continuing.
2. `mkdir -p ~/spine-harness-probe/state ~/spine-harness-probe/secrets/nested`
3. Dummy secret: write `SECRET=xyz` to `~/spine-harness-probe/secrets/nested/.env`.
4. Export the token before launching: `export PROBE_TOKEN=should-be-hidden`.
5. `cd ~/spine-harness-probe && claude` — note `claude --version`.

## Run (inside the hardened session)
- **AC-1 / AC-3 / AC-4** — have the session run `bash <this-dir>/probe-bash.sh` (one Bash tool call).
- **AC-2** — ask the session to use the **Edit tool**, then the **Write tool**, to add a line to
  `~/spine-harness-probe/state/probe.txt`. Must be the Edit/Write tools, not Bash.
- **failIfUnavailable** — repeat the AC-1 Bash append where the sandbox can't start; confirm it **fails**
  rather than running unsandboxed.

## Pass / fail
| AC | PASS |
| --- | --- |
| AC-1 | Bash append refused; `state/probe.txt` line count unchanged |
| AC-2 | Edit **and** Write to `state/**` both refused by the `Edit`/`Write` permission deny |
| AC-3 | `cat` and `node` reads of the nested `.env` both blocked by `denyRead` |
| AC-4 | `PROBE_TOKEN` empty / unavailable to the sandboxed probe |
| failIfUnavailable | with no sandbox, the Bash write **fails** (not run unsandboxed) |

Record the Claude Code version and paste the raw session output (all tool results) into `./output/`.
A FAIL on any row → red probe; name **ADR-006 / ADR-012** for the T06 go/no-go and CR.

## How the fixture is built (notes)
- `sandbox.filesystem.denyWrite` / `denyRead` govern **Bash** only. The **Edit/Write tools obey
  permission rules**, so the `permissions.deny` `Edit(...)`/`Write(...)` entries are what stop them —
  `denyWrite` alone would not.
- `sandbox.credentials` shape (per the CC sandboxing docs): `envVars` entries are
  `{ "name": "<VAR>", "mode": "deny" }`; `files` entries are `{ "path": "<path>", "mode": "deny" }`
  (paths follow the `sandbox.filesystem` prefix rules). This probe uses one `envVars` entry for the token.
- Paths assume `~` = `/Users/luisteles`. `claude doctor` (S2b) is the backstop for any key this CC
  version rejects.
