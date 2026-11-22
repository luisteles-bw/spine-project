---
id: SECURITY
type: security
title: Spine threat model and security requirements
stage: discovery
status: approved
version: 1
refs: [SPEC, REQUIREMENTS]
visibility: internal
author: architect
updated: 2026-11-22
---

The spine's job is to keep AI agents inside limits. Its worst failure is an agent getting around a
limit: passing a gate, writing outside its scope, or reaching a secret. The Architect refines this
in the architecture stage.

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
| T1 | An agent passes a gate | Claude runs `spine approve`, or edits state files | SEC-001, SEC-002, SEC-003 |
| T2 | An agent writes outside its role or task scope | The Coder edits tests or another module | SEC-004 |
| T3 | Secret exposure | A check prints a token; an agent reads `.env` via `node -e` | SEC-005, SEC-006, SEC-007 |
| T4 | Prompt injection | Text in a client file tells the agent to push code or exfiltrate data | SEC-008 |
| T5 | Command injection in the spine | A branch name or title is pasted unescaped into a shell command | SEC-009 |
| T6 | Path traversal | A document id or ref like `../../.ssh` resolves outside the workspace | SEC-010 |
| T7 | Malicious or invented dependency | An agent adds a look-alike package | SEC-011 |
| T8 | Record tampering | A verify record is edited after the fact | SEC-012 |
| T9 | Over-shared CRM data | Internal documents or secrets synced to Twenty | SEC-013 |

## Security requirements
| ID | Requirement |
| --- | --- |
| SEC-001 | `spine approve` and `spine reject` refuse to run inside an agent's shell. Detect it through the environment Claude Code sets for its commands (verify the exact variable in the architecture stage) and through the guard hook. |
| SEC-002 | Only spine commands write `project/state/`. The guard blocks direct edits, and the spine detects state that doesn't match the log. |
| SEC-003 | Every gate decision is an event with who, when and the note. |
| SEC-004 | `spine guard` allows writes only inside the active role's paths and the task's `scope.touch`; the Coder can never edit the current attempt's tests. |
| SEC-005 | Secrets are never written to events, `checks.json`, logs or Twenty. Known secret values are redacted from captured output. |
| SEC-006 | Check secrets come from the OS keychain and are injected only into the check's child process. |
| SEC-007 | The workspace `settings.json` enables Claude Code's sandbox and denies reading env files and credential folders. |
| SEC-008 | Content from `inputs/`, web pages, MCP servers and client files is passed to agents as data, labelled as untrusted. Roles that read it have no shell. |
| SEC-009 | The spine never builds shell strings. It runs processes with argument arrays and validates every id and slug against a strict pattern. |
| SEC-010 | Every path the spine resolves is checked to stay inside the workspace after resolving symlinks. |
| SEC-011 | Any change to a dependency list opens the `new_dependency` gate, showing package name, publisher, version and age. |
| SEC-012 | Each submitted record's hash is stored in its event; `spine check` reports any mismatch. |
| SEC-013 | `spine sync` sends only whitelisted fields, and only documents allowed by their `visibility` and type. |
