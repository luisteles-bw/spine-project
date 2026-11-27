# P01 operator sheet — run T01–T05 (terminal CLI, zsh)

Run each probe in a **fresh Terminal window**; paste that section's boilerplate block first
(`setopt interactivecomments` lets the `#` comments paste cleanly in an interactive zsh). Copy a new
`settings.json` per probe, set env/PATH, then launch a fresh `claude` so the settings load.

**Prerequisites:** H0 is in `~/.claude/settings.json` (user scope, machine-wide):
`sandbox.failIfUnavailable:true`, `sandbox.allowUnsandboxedCommands:false`,
`sandbox.excludedCommands:["spine *"]`, `sandbox.network.strictAllowlist:true`, and (added 2026-11-27,
finding **F-1**) top-level `disableAutoMode` + `permissions.disableBypassPermissionsMode`.

**Launch mode:** T01–T02 ran under **auto mode** and are shown as-run. **From T03 on, launch with
`claude --permission-mode default`** (not bare `claude`) so no auto-mode auto-approval masks the
permission layer (F-1).

**Evidence (every probe):** in the session run `/export` and save the transcript as
`probes/<name>/output/<name>-session<n>.txt` (one per session). Also copy the named log/state files
below. The verifier judges from those transcripts + files.

---

## One-time setup (run once)

```zsh
setopt interactivecomments
WS=~/spine-harness-probe
R=~/Desktop/projects/BrightWeb/spine/spine-workspace/project/increments/I01-spine-mvp/3-development/P01-harness-spike
mkdir -p $WS/{state,secrets/nested,bin,hooks,.claude}
printf 'SECRET=xyz\n' > $WS/secrets/nested/.env
echo seed > $WS/state/probe.txt                      # seed so Edit has a file (AC-2 must fail on PERMISSION, not missing-file)
cp $R/probes/denywrite/probe-bash.sh $WS/
cp $R/probes/excluded/bin/spine $R/probes/excluded/bin/spine-admin $WS/bin/
cp $R/probes/exit2/hook.sh $WS/hooks/
cp $R/probes/agent-type/log-hook.sh $WS/hooks/
chmod +x $WS/bin/* $WS/hooks/*
```

---

## T01 — denyWrite · Edit-deny · denyRead · credentials  (ADR-006, ADR-012)

```zsh
setopt interactivecomments
WS=~/spine-harness-probe
R=~/Desktop/projects/BrightWeb/spine/spine-workspace/project/increments/I01-spine-mvp/3-development/P01-harness-spike
```

Copy the settings:

```zsh
cp $R/probes/denywrite/fixture.settings.json $WS/.claude/settings.json
```

Set the token, then launch:

```zsh
export PROBE_TOKEN=should-be-hidden
```

```zsh
cd $WS && claude
```

Prompts (type each into the session):

```text
Use Bash to run: bash probe-bash.sh
```

```text
Use the Edit tool to append a line to ~/spine-harness-probe/state/probe.txt
```

```text
Use the Write tool to create ~/spine-harness-probe/state/probe2.txt containing the word hi
```

```text
/export
```

Save evidence (terminal):

```zsh
cp $WS/state/probe.txt $R/probes/denywrite/output/state-probe.txt
```

**PASS:** Bash append refused (`probe.txt` still reads `seed`); Edit **and** Write both refused with a
**permission** error (not "file not found"); nested `.env` read blocked; `PROBE_TOKEN` empty.
`failIfUnavailable`: **not testable on macOS tier 1** — covered by docs + `doctor` key recognition.

---

## T02 — excludedCommands asymmetry  (ADR-012)

```zsh
setopt interactivecomments
WS=~/spine-harness-probe
R=~/Desktop/projects/BrightWeb/spine/spine-workspace/project/increments/I01-spine-mvp/3-development/P01-harness-spike
```

```zsh
cp $R/probes/excluded/fixture.settings.json $WS/.claude/settings.json
```

```zsh
export PATH="$WS/bin:$PATH"
```

```zsh
cd $WS && claude
```

Prompts:

```text
Use Bash to run: spine probe-write
```

```text
Use Bash to run: spine-admin probe-write
```

```text
Use Bash to run: ~/spine-harness-probe/bin/spine-admin probe-write
```

```text
/export
```

Save evidence (terminal):

```zsh
cp $WS/state/probe.txt $R/probes/excluded/output/state-probe.txt
```

**PASS:** `spine probe-write` writes `state/` (unsandboxed); `spine-admin probe-write` (prefix) →
permission refusal (not the OS boundary); full-path `spine-admin` → `denyWrite` block (the OS boundary).

---

## T03 — PreToolUse exit codes  (ADR-010)

```zsh
setopt interactivecomments
WS=~/spine-harness-probe
R=~/Desktop/projects/BrightWeb/spine/spine-workspace/project/increments/I01-spine-mvp/3-development/P01-harness-spike
```

Settings for AC-1/AC-2, default the toggle to 2:

```zsh
cp $R/probes/exit2/fixture.settings.json $WS/.claude/settings.json
echo 2 > $WS/hooks/exit-code
```

```zsh
cd $WS && claude
```

AC-1 (exit 2 blocks):

```text
Use Bash to run: echo PROBE_MARKER ok
```

AC-2 (flip to exit 1 — hook re-reads the file, no relaunch — then re-run):

```text
Use Bash to run: echo 1 > ~/spine-harness-probe/hooks/exit-code
```

```text
Use Bash to run: echo PROBE_MARKER ok
```

```text
/export
```

AC-3 (fail-closed): exit the session, then in the terminal confirm no guard + swap settings + relaunch:

```zsh
command -v spine-guard || echo "spine-guard not on PATH"
```

```zsh
cp $R/probes/exit2/fixture-failclosed.settings.json $WS/.claude/settings.json
cd $WS && claude
```

```text
Use Bash to run: echo hello
```

```text
/export
```

**PASS:** exit 2 blocks the marker call; exit 1 lets it run; with `spine-guard || exit 2` and
`spine-guard` missing, **any** Bash call is blocked (fail closed).

---

## T04 — agent_type · network · unsandboxed hook  (ADR-010)

```zsh
setopt interactivecomments
WS=~/spine-harness-probe
R=~/Desktop/projects/BrightWeb/spine/spine-workspace/project/increments/I01-spine-mvp/3-development/P01-harness-spike
```

```zsh
cp $R/probes/agent-type/fixture.settings.json $WS/.claude/settings.json
: > $WS/hooks/agent-type.log
```

```zsh
cd $WS && claude
```

Prompts:

```text
Use Bash to run: echo main-session-call
```

```text
Dispatch a general-purpose subagent that runs three separate Bash commands: echo one, then echo two, then echo three
```

```text
Use Bash to run: curl -sS https://example.com
```

```text
/export
```

Save evidence (terminal):

```zsh
cp $WS/hooks/agent-type.log $R/probes/agent-type/output/agent-type.log
cp $WS/state/hook-unsandboxed.txt $R/probes/agent-type/output/hook-unsandboxed.txt
```

**PASS:** subagent firings carry `agent_type` (same value across all 3); the main-session firing has
none/sentinel; the network `curl` is denied with **no** per-domain prompt; `hook-unsandboxed.txt` exists
(hook wrote into the `denyWrite` dir).

---

## T05 — resolution + settings keys  (ADR-012, ADR-017, SEC-020)

```zsh
setopt interactivecomments
WS=~/spine-harness-probe
R=~/Desktop/projects/BrightWeb/spine/spine-workspace/project/increments/I01-spine-mvp/3-development/P01-harness-spike
```

Confirm H0 by eye (do **not** overwrite your user settings), then copy the workspace tier:

```zsh
cat ~/.claude/settings.json   # confirm: sandbox.failIfUnavailable:true, allowUnsandboxedCommands:false, excludedCommands:["spine *"], network.strictAllowlist:true
```

```zsh
cp $R/probes/resolution/workspace-settings.sample.json $WS/.claude/settings.json
```

```zsh
export PATH="$WS/bin:$PATH"
```

```zsh
cd $WS && claude --permission-mode default
```

Prompts (AC-1 shadow + AC-2/AC-5 keys):

```text
Use Bash to run: command -v spine
```

```text
Use Bash to run: spine probe-write
```

F-2 open question (does `Bash(spine-admin *)` match a bare full path, or did auto mode refuse it in T02 session 1?) — this session is launched `--permission-mode default`, so run:

```text
Use Bash to run: ~/spine-harness-probe/bin/spine-admin probe-write
```

Record which happens — **refused with no prompt** → the `Bash(spine-admin *)` rule matched the full path; **a prompt appears, or it runs** → in T02 session 1 it was auto mode, not the rule. Put the answer into findings **F-2**.

```text
/doctor
```

```text
/export
```

AC-2/AC-5 via the CLI checker (terminal) — record whether it validates settings at all:

```zsh
claude doctor
```

**PASS:** record whether a PATH-placed `spine` runs unsandboxed (the shadow risk — **alias case is the
known residual**, mitigated by shell-rc write denies + preflight); every settings key recognised;
`strictAllowlist` effective on v2.1.325; `/doctor` (and/or `claude doctor`) report no rejected keys.

> Alias note: Claude Code captures aliases from `~/.zshrc` at session start, so a terminal `alias spine=…`
> plus a terminal `spine x` tests nothing — dropped. The alias vector is covered by the rc-file write
> denies + preflight, recorded as a residual.

---

## After all five
Fill `../findings.md` from the transcripts + files in each `output/`, set the go/no-go, then the phase
review (verifier + security) runs and you `/approve` — P01 exits (records-only, no `phase_pr`).
