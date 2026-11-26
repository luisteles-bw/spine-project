# P01-T03 — PreToolUse exit 2 blocks; exit 1 doesn't; missing guard fails closed

Proves ADR-010's fail-closed design: Claude Code blocks a tool call **only** on PreToolUse exit code
**2**, so a guard crash or missing binary fails *open* unless wrapped as `spine-guard || exit 2`.

> Reuses the T01 throwaway workspace; runs in the hardened session.

## Setup (human, once)
1. Install the hook script into a hooks dir:
   `mkdir -p ~/spine-harness-probe/hooks && cp hook.sh ~/spine-harness-probe/hooks/ && chmod +x ~/spine-harness-probe/hooks/hook.sh`
2. Default the toggle to block: `echo 2 > ~/spine-harness-probe/hooks/exit-code`.
3. Merge `fixture.settings.json` here into `~/spine-harness-probe/.claude/settings.json` (a `PreToolUse`
   hook on the `Bash` matcher pointing at `hook.sh`). Run `claude doctor` (S2b).
4. `cd ~/spine-harness-probe && claude`. The hook only acts on Bash commands containing `PROBE_MARKER`,
   so the session stays usable for everything else.

## Run (inside the hardened session)
- **AC-1 (exit 2 blocks)** — with `exit-code` = `2`, run a Bash command `echo PROBE_MARKER ok`. It must be
  **blocked** (no `PROBE_MARKER ok` output).
- **AC-2 (exit 1 doesn't block)** — `echo 1 > ~/spine-harness-probe/hooks/exit-code` (no relaunch
  needed), run `echo PROBE_MARKER ok` again. It must **run** (`PROBE_MARKER ok` prints).
- **AC-3 (missing guard fails closed)** — swap the hook to `fixture-failclosed.settings.json`
  (command `spine-guard || exit 2`, with `spine-guard` **not** on PATH) and **relaunch** claude. Any
  Bash call is now **blocked** — `spine-guard` not-found → `|| exit 2` → fail closed. Run one Bash
  command to confirm, then revert the settings.

## Pass / fail
| AC | PASS |
| --- | --- |
| AC-1 | exit 2 → the marker Bash command is blocked (does not run) |
| AC-2 | exit 1 (any non-2) → the marker Bash command runs (not blocked) |
| AC-3 | `spine-guard || exit 2` with `spine-guard` missing → the Bash call is blocked (fail closed) |

If exit 1 blocks, or exit 2 doesn't, or the missing binary fails **open** → red probe; name **ADR-010**
for the T06 go/no-go. Record the CC version; paste raw output into `./output/`.

## Notes
- The matcher is the **tool name** `Bash` (hooks fire per tool, not per command text); `hook.sh` narrows
  to `PROBE_MARKER` so the session stays usable. The fail-closed variant has no such guard — it blocks
  **all** Bash — so run one command and revert.
- Hook `command` paths are absolute (`~/spine-harness-probe/hooks/hook.sh`), unlike permission-rule
  paths; `claude doctor` (S2b) confirms the hook block is accepted.
