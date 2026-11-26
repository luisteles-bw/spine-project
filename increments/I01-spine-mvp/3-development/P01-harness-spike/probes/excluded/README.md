# P01-T02 — excludedCommands lets `spine` write, blocks a non-excluded binary

Proves the asymmetry ADR-012 depends on: an **excluded** `spine *` command writes state (unsandboxed),
while a **non-excluded** binary (`spine-admin`) is sandboxed and blocked by `denyWrite` — the OS
boundary, not an env/TTY/permission-prefix trick.

> Reuses the T01 throwaway workspace. Runs in the hardened session, never the real workspace.

## Setup (human, once)
1. Confirm H0: `~/.claude/settings.json` has `sandbox.excludedCommands: ["spine *"]` (that key is
   user-scope; it does **not** live in this fixture).
2. Merge `fixture.settings.json` here into `~/spine-harness-probe/.claude/settings.json` (denyWrite on
   `state/` + `failIfUnavailable` + the `Bash(spine-admin *)` permission deny). Run `claude doctor` (S2b).
3. Copy the stubs into a **probe-only PATH dir** and make them executable:
   `mkdir -p ~/spine-harness-probe/bin && cp bin/spine bin/spine-admin ~/spine-harness-probe/bin/ && chmod +x ~/spine-harness-probe/bin/*`
4. In the **probe terminal only**: `export PATH="$HOME/spine-harness-probe/bin:$PATH"`.
5. `cd ~/spine-harness-probe && claude` — note `claude --version`.

## Run (inside the hardened session)
- **AC-1** — run `spine probe-write` (bare command → matched by `excludedCommands`, runs unsandboxed).
- **AC-2** — run `spine-admin probe-write` (bare command → prefix form).
- **AC-3** — run `$HOME/spine-harness-probe/bin/spine-admin probe-write` (**full path**).

## Pass / fail
| AC | PASS |
| --- | --- |
| AC-1 | `spine probe-write` succeeds; the line lands in `state/probe.txt` (ran unsandboxed) |
| AC-2 | `spine-admin probe-write` is refused by the permission deny `Bash(spine-admin *)` — a permission refusal, **not** proof of the OS boundary |
| AC-3 | the **full-path** `spine-admin` (unmatched by the prefix deny) is blocked by sandbox `denyWrite` — this is the OS boundary |

A FAIL (`spine` blocked, or either `spine-admin` form landing a write) → red probe; name **ADR-012** for
the T06 go/no-go. Record the CC version; paste raw output into `./output/`.

## Notes
- The whole point: AC-2 and AC-3 both run `spine-admin`, but only AC-3 proves the sandbox stops it — AC-2
  only shows the (bypassable) permission prefix rule.
- Cleanup after T06: `export PATH` restored, `~/spine-harness-probe/bin` removed and stubs deleted —
  `excludedCommands: ["spine *"]` is machine-wide, so no stub `spine` may linger on `PATH`.
