# P01-T05 — `spine` resolution + every settings key is recognised

Proves SEC-020 / ADR-012 / ADR-017: the excluded `spine` can't be shadowed by a PATH entry (or alias),
every key the hardened config uses is recognised by the installed Claude Code, and the right
settings-file scope makes each key take effect.

> Runs in the throwaway workspace (cwd `~/spine-harness-probe`), hardened session.

## Setup (human, once)
1. H0 user-scope keys in `~/.claude/settings.json` — see `user-settings.sample.json` here.
2. Workspace tier in `~/spine-harness-probe/.claude/settings.json` — see `workspace-settings.sample.json`
   (the full switch-over workspace tier the earlier probes layered on; permission paths relative,
   `sandbox.filesystem` absolute, `credentials.envVars` `{name,mode}`).
3. Stub for AC-1: `mkdir -p ~/spine-harness-probe/bin && cp bin/spine ~/spine-harness-probe/bin/ && chmod +x ~/spine-harness-probe/bin/spine`.

## Run
### AC-1 — PATH shadow (required); alias (optional)
- In the probe terminal: `export PATH="$HOME/spine-harness-probe/bin:$PATH"`, then run `spine x`. Record
  whether the **stub** ran (shadowed) or `excludedCommands` still matched the intended binary;
  `command -v spine` shows resolution.
- Optional alias case: `alias spine='echo ALIAS spine'`, repeat, then `unalias spine` and **restore
  `~/.zshrc`** if you touched it.

### AC-2 / AC-5 — key recognition
With both settings files loaded, run **`claude doctor`** (CLI) and, in a session, **`/doctor`**. Record
which one surfaces rejected/unknown keys (the CLI `claude doctor` may be installation-only; `/doctor` is
the full setup checkup — capture the behaviour you observe for each), and confirm **none** of these are
rejected:
`sandbox.enabled`, `sandbox.failIfUnavailable`, `sandbox.allowUnsandboxedCommands`,
`sandbox.excludedCommands`, `sandbox.network.allowedDomains`, `sandbox.network.strictAllowlist`,
`sandbox.filesystem.denyWrite`, `sandbox.filesystem.denyRead`, `sandbox.credentials`,
`permissions.disableBypassPermissionsMode`, top-level `disableAutoMode`.

### AC-3 — scope matrix
For each of `allowUnsandboxedCommands:false`, `failIfUnavailable:true`, `excludedCommands`,
`network.strictAllowlist:true`: place it in **workspace** vs **user** scope and record which scope makes
it take effect.

### AC-4 — strictAllowlist + version
Confirm `sandbox.network.strictAllowlist: true` is recognised and effective; record `claude --version`
(must be **≥ v2.1.219**; installed here is 2.1.325).

## Record (paste into ./output/)
- `claude --version`; AC-1 (stub vs excluded, `command -v spine`, alias result); AC-2/AC-5 doctor + /doctor
  output and any unknown/rejected key.
- AC-3 scope matrix:

| Key | Workspace takes effect? | User takes effect? | Required scope |
| --- | --- | --- | --- |
| allowUnsandboxedCommands:false |  |  |  |
| failIfUnavailable:true |  |  |  |
| excludedCommands |  |  |  |
| network.strictAllowlist:true |  |  |  |

## Pass / fail
| AC | PASS |
| --- | --- |
| AC-1 | a PATH entry/alias does **not** change what the excluded `spine` runs (or, if it can, it's recorded as a finding) |
| AC-2 | every key above is recognised; no unknown-setting warning |
| AC-3 | the required scope for each key is recorded and matches ADR-012 (user scope for the four H0 keys) |
| AC-4 | `strictAllowlist: true` recognised + effective; version ≥ v2.1.219 |
| AC-5 | `claude doctor` / `/doctor` report no rejected or unknown entries |

A FAIL (shadowing exploitable, any key silently ignored, or doctor rejects a key) → red probe; name
**ADR-012 / ADR-017** (SEC-020) for the T06 go/no-go.

## Notes
- Open question this probe resolves: does the **CLI `claude doctor`** validate project settings, or only
  the in-session **`/doctor`**? Record it — T05-AC-5 names `claude doctor`; if only `/doctor` validates
  settings, flag it for an AC-5 wording correction.
- Cleanup after T06: `export PATH` restored, `~/spine-harness-probe/bin` removed, `~/.zshrc` restored.
