---
id: SECURITY
type: security
title: Spine threat model and security requirements
stage: discovery
status: approved
version: 4
refs: [SPEC, REQUIREMENTS]
visibility: internal
author: architect
updated: 2026-11-24
---

The spine's job is to keep AI agents inside limits. Its worst failure is an agent getting around a
limit: passing a gate, writing outside its scope, or reaching a secret. The architecture stage
refined the mechanisms (ADR-006, ADR-009, ADR-010, ADR-011, ADR-012, ADR-015, ADR-017).

**Tiering (ADR-017).** These security guarantees are claimed only on **macOS (tier 1)**, where the
red-team checklist (ADR-015) is verified. **Linux and WSL2 are tier 2** — exercised in CI but not
red-teamed until agent sessions run there. The real controls are the Claude Code **sandbox**, the
spine's **submit-time** scope-diff and record hashes, and the **OS-enforced** human-only boundary; the
guard hook is a fast tripwire, not the wall.

## Assets
| Asset | Where it lives | Why it matters |
| --- | --- | --- |
| Client source code | `code/` repos | Confidential, owned by the client |
| Project records | `project/` repos, the event log | The audit trail; must not be rewritten |
| Gate decisions | Event log | The human's authority |
| Credentials | OS keychain: Twenty API key, GitHub via `gh auth`, check secrets | Access to client systems |
| Client and lead data | Twenty | Personal data under GDPR |

## Threats
| ID | Threat | Example | Mitigation (SEC ids) |
| --- | --- | --- | --- |
| T1 | An agent passes a gate | Claude runs `spine-admin approve`, or edits state files | SEC-001, SEC-002, SEC-003 |
| T2 | An agent writes outside its role or task scope | The Coder edits tests or another module | SEC-004 |
| T3 | Secret exposure | A check prints a token; an agent reads `.env` via `node -e` | SEC-005, SEC-006, SEC-007 |
| T4 | Prompt injection | Text in a client file tells the agent to push code or exfiltrate data | SEC-008 |
| T5 | Command injection in the spine | A branch name or title is pasted unescaped into a shell command | SEC-009 |
| T6 | Path traversal | A document id or ref like `../../.ssh` resolves outside the workspace | SEC-010 |
| T7 | Malicious or invented dependency | An agent adds a look-alike package | SEC-011 |
| T8 | Record tampering | A verify record is edited after the fact | SEC-012 |
| T9 | Over-shared CRM data | Internal documents or secrets synced to Twenty | SEC-013 |
| T10 | Planted standing instructions | A client file, `code/CLAUDE.md` or an agent file tells every later session to misbehave | SEC-014 |
| T11 | Silent loss of protection | The sandbox is unavailable, or a `settings.local.json` / user setting weakens the rules | SEC-015 |
| T12 | The unsandboxed spine runs project code | A git hook, fsmonitor, scaffolder or check executes with the spine's access | SEC-016 |
| T13 | Check tampering | Editing `package.json` scripts, a test config, or `vitest -u` to force a pass | SEC-017 |
| T14 | Supply chain via local tooling | A local MCP server or `@latest` dependency runs unreviewed code at session start | SEC-018 |
| T15 | An agent changes its own permissions | Editing `.claude/`, `~/.claude/` or `spine.yaml` to loosen the rules | SEC-019 |
| T16 | PATH / alias hijack of `spine` | A shell alias or workspace-relative PATH entry shadows the excluded `spine` | SEC-020 |

## Security requirements
| ID | Requirement |
| --- | --- |
| SEC-001 | `approve`, `reject` and the other human-only commands live in a **separate `spine-admin` binary that is not in the sandbox's `excludedCommands`**, so an agent that runs it is sandboxed and `denyWrite` blocks it; the human runs it in a terminal outside Claude Code. Env-var/TTY detection is **not** relied on (both are spoofable). A `Bash(spine-admin *)` deny gives agents a clean refusal. (ADR-012) |
| SEC-002 | Only the excluded `spine` writes `project/state/**`, enforced by the sandbox `denyWrite` (not the guard). The log is append-only with `seq` = line position (a gap or duplicate is a hard stop), and `project/` commits carry `Spine-Seq` so git history and the event log cross-check. (ADR-006, ADR-012) |
| SEC-003 | Every gate decision is an event with who, when and the note. |
| SEC-004 | The real scope controls are at **`submit`**: the diff must stay inside the task's `scope.touch`, and the test files hashed at "Tests ready" must be unchanged (so the Coder can't edit this attempt's tests, snapshots or fixtures, nor via `vitest -u`). **`spine-guard`** is a fast PreToolUse **tripwire** (realpath scope match, per-role shape allowlist); the sandbox is the wall. (ADR-010, ADR-011) |
| SEC-005 | Secrets are never written to events, `checks.json`, logs or Twenty. Injected secret values — and their base64/URL-encoded forms — are redacted from captured output. (ADR-011) |
| SEC-006 | Check secrets come from the OS keychain (or a 0600 WSL fallback) and are injected only into the check's child process, least-privilege per check. After each check, spine sweeps changed + untracked files for the exact injected values; a hit fails the check. (ADR-011) |
| SEC-007 | The workspace `settings.json` sets `sandbox.enabled` + **`failIfUnavailable: true`** + `allowUnsandboxedCommands: false`, disables bypass/auto permission modes, denies reading env files and credential folders, and `denyWrite`-mirrors every Edit/Write deny. It is installed from the **package templates** (`spine-admin`), never editable by agents. (ADR-012) |
| SEC-008 | Content from `inputs/`, web pages, MCP servers and client files is **data, never instructions**, carried with `trusted: false` in the context list. The Coder and others do have a shell, so the containment is the sandbox (**agent Bash network = none**), the guard's per-role shape + tool allowlist, and submit-time checks — not the absence of a shell. (ADR-008, ADR-010) |
| SEC-009 | The spine never builds shell strings. It runs processes with argument arrays and validates every id and slug against a strict pattern. |
| SEC-010 | Every path the spine resolves is checked to stay inside the workspace after resolving symlinks. |
| SEC-011 | Any change to a dependency list opens the `new_dependency` gate, showing package name, publisher, version and age. |
| SEC-012 | Each submitted record's hash (raw bytes at submit) is stored in its event; records are never edited afterwards, and **every gate re-checks all record hashes** (not only `spine check`). (ADR-006) |
| SEC-013 | `spine sync` sends only whitelisted fields, and only documents allowed by their `visibility` and type. |
| SEC-014 | `code/CLAUDE.md`, `code/AGENTS.md` and the agent/command files are write-protected; untrusted content is labelled `trusted: false`; a check fails if any agent doc tells agents to edit `STATE.md`. (ADR-013, ADR-016) |
| SEC-015 | `sandbox.failIfUnavailable: true` makes a missing sandbox fail rather than run unprotected; `spine doctor` audits that settings match the template and no `settings.local.json`/user override weakens them; after switch-over, state-changing commands refuse (exit 3) if the sandbox or guard hook is off. (ADR-017) |
| SEC-016 | The spine runs outside the sandbox but never executes project code: git runs with `core.hooksPath=/dev/null` + `core.fsmonitor=false`; the scaffolder, `pnpm install` and checks run **inside** `@anthropic-ai/sandbox-runtime`. (ADR-009, ADR-011, ADR-013) |
| SEC-017 | Checks call tools directly (`pnpm exec vitest/eslint/tsc`), never `package.json` scripts; check configs are in every Coder task's `forbid`; the guard shape allowlist forbids `vitest -u/--update`; test files + snapshots + fixtures are hashed at "Tests ready". (ADR-011, ADR-010) |
| SEC-018 | stdio MCP servers are pinned to exact versions (never `@latest`); `.mcp.json` is write-protected (official servers only); dependency installs are denied for agents and run by the human after the `new_dependency` gate. (ADR-013, ADR-011) |
| SEC-019 | Agents cannot edit the rules that bind them: `.claude/**`, `~/.claude/**`, `spine.yaml` and shell rc files are denied (Edit/Write + sandbox `denyWrite`). (ADR-012) |
| SEC-020 | Preflight / `spine doctor` verify `spine` resolves to the installed package outside the workspace and that PATH has no relative or workspace entries; shell rc files are write-protected so an alias can't shadow `spine`. (ADR-012, ADR-017) |
