---
id: REQUIREMENTS
type: requirements
title: Spine MVP requirements
stage: discovery
status: approved
version: 3
refs: [SPEC, CONCEPT]
visibility: internal
author: architect
updated: 2026-11-24
---

Derived from `SPEC` v0.4. Each requirement names the spec section it comes from. **Must** is
needed for the first client project; **Should** before the end of I01; **Could** if time allows.
The Architect may refine wording and priority in the architecture stage (bump `version`).

## Workspace and initialisation
| ID | Requirement | Acceptance (summary) | Priority | Spec section |
| --- | --- | --- | --- | --- |
| REQ-001 | `spine-admin init` creates a workspace: `code/`, `project/`, `.claude/`, `CLAUDE.md`, `.mcp.json`, `spine.yaml` | Running it in an empty folder produces the layout, both repos initialised, and increment I01 | Must | Workspace layout |
| REQ-002 | `spine-admin init --profile <name>` runs the profile's official scaffolder and applies its contract | The four root scripts exist and pass on the fresh scaffold; CI and Dependabot files exist | Must | Client code repo |
| REQ-003 | Profile `nextjs-static` ships with init | A Next.js static site builds and tests green straight after init | Must | Client code repo |
| REQ-004 | `project.yaml` records repo owner, hosting owner and profile per project | Values are validated and synced to Twenty | Should | Spine CLI |
| REQ-005 | `spine-admin upgrade` re-installs the framework's `claude/` assets into a workspace and records the version | The workspace's framework version changes only through this command | Could | Workspace layout |

## State, lifecycles and gates
| ID | Requirement | Acceptance (summary) | Priority | Spec section |
| --- | --- | --- | --- | --- |
| REQ-010 | An append-only event log is the single source of truth | `graph.json` rebuilt from the same events is byte-identical every time | Must | Project docs structure |
| REQ-011 | Five lifecycles (increment stages, phase, task, ticket, change request) as fixed transition rules | An invalid transition is refused with an error naming the current state and allowed moves | Must | Lifecycles |
| REQ-012 | Gates from `spine.yaml` pass only through `spine-admin approve` / `spine-admin reject` | No other command or file edit moves a node past a gate | Must | Spine CLI |
| REQ-013 | `spine-admin approve` cannot change state from an agent's shell | Run from Claude Code's Bash tool it is sandboxed and `denyWrite` blocks it (nothing changes); `Bash(spine-admin *)` is denied for a clean refusal | Must | Security |
| REQ-014 | Retry ladder: 3 attempts, then one replan, then Blocked with a change request | The fourth failure of a replanned task raises a CR automatically | Must | Lifecycles |
| REQ-015 | Phase split (before work) and cut (after work starts), one level only | A part cannot split again; every split or cut opens the plan gate | Should | Splitting work |
| REQ-016 | Size limits enforced at plan apply | A phase over 8 tasks or 24 estimated hours, or a task of size L, is refused | Must | Splitting work |

## Documents
| ID | Requirement | Acceptance (summary) | Priority | Spec section |
| --- | --- | --- | --- | --- |
| REQ-020 | Every document type has a schema; submit validates frontmatter and required headings | An invalid document is refused with field-level errors an agent can act on | Must | IDs and document schemas |
| REQ-021 | Documents reference each other by id; the spine resolves ids to paths | A dangling reference is reported by `spine check --trace` | Must | IDs and document schemas |
| REQ-022 | A template per document type ships with the framework | `spine next` names the template for every step | Must | IDs and document schemas |
| REQ-023 | Records are immutable once submitted | A changed record is detected (its hash is in the event log) and reported | Should | Project docs structure |
| REQ-024 | `spine context <id>` assembles the reading list for a node deterministically | Same state gives the same list; it includes refs, parent and the latest verify record | Must | Spine CLI |
| REQ-025 | `spine check --trace` reports coverage gaps | Lists requirements with no task, criteria with no test, done tasks with no commit | Should | IDs and document schemas |

## Workflow commands
| ID | Requirement | Acceptance (summary) | Priority | Spec section |
| --- | --- | --- | --- | --- |
| REQ-030 | `spine status` shows the tree, open gates, open CRs and the next action with its owner | Output fits one screen for a 10-phase increment | Must | Spine CLI |
| REQ-031 | `spine next --json` returns one step: node, role, files to read, files to write, template, schema | The output validates against its own JSON schema | Must | Spine CLI |
| REQ-032 | `spine submit <id>` validates, records the event and moves the state | Definition of Done is enforced for tasks | Must | Delivery standards |
| REQ-033 | `spine plan apply` checks Definition of Ready and creates phase and task nodes | A task without scope, size, estimate or criteria is refused | Must | Delivery standards |
| REQ-034 | `spine session start/close` manages resumable discovery and architecture sessions | Closing writes open points; starting resumes from them | Should | Project docs structure |
| REQ-035 | Switch-over: import the bootstrap `STATE.md` into the event log | After import, `spine status` matches `STATE.md` | Must | Bootstrap |

## Checks, git and PRs
| ID | Requirement | Acceptance (summary) | Priority | Spec section |
| --- | --- | --- | --- | --- |
| REQ-040 | `spine check` runs the configured commands and writes `checks.json` | Exit codes and summaries recorded; secrets never appear in output | Must | Spine CLI |
| REQ-041 | Secrets for checks come from the OS keychain and reach only the check process | Agents' shells never receive them | Should | Secrets and security |
| REQ-042 | Branch per phase, commit per task, Conventional Commits with trailers | `git log --grep "Task: P03-T02"` finds the task's commit | Must | Git conventions |
| REQ-043 | `spine pr <phase>` pushes and opens the PR with a generated body | Body lists tasks, criteria, checks, security verdict and manual criteria | Must | Git conventions |
| REQ-044 | Changelog and semantic version tag at release | Generated from commits, grouped by type | Should | Git conventions |

## Agents and guard
| ID | Requirement | Acceptance (summary) | Priority | Spec section |
| --- | --- | --- | --- | --- |
| REQ-050 | The framework ships five agents, the slash commands and `settings.json` | `spine-admin init` installs them; they call real spine commands, not `STATE.md` | Must | Agents and Claude Code setup |
| REQ-051 | `spine-guard` (a PreToolUse hook) enforces per-role write scopes and the task's file scope | A Coder edit outside `scope.touch` is blocked with a reason | Must | Agents and Claude Code setup |
| REQ-052 | The guard inspects whole Bash commands for secret access and gate commands | `node -e` reading `.env`, or `spine-admin approve` from an agent, is blocked | Should | Secrets and security |

## Change requests, increments, tickets, time, export
| ID | Requirement | Acceptance (summary) | Priority | Spec section |
| --- | --- | --- | --- | --- |
| REQ-060 | `spine cr raise` by the human, any agent or the spine; only the human decides | Raising freezes only the nodes the CR touches | Must | Splitting work and change requests |
| REQ-061 | `spine increment new` with billing items (fixed, hourly, support bundle) and rates as objects | Support bundle price follows the formula in `spine.yaml` | Should | Spine CLI |
| REQ-062 | `spine ticket new / fix` with severity, bundle coverage and a hotfix branch | A fix runs the task lifecycle on `hotfix/<id>-<slug>` | Should | Lifecycles |
| REQ-063 | `spine time` logs human hours; agent session time is logged automatically | Hours roll up per billing item | Should | Spine CLI |
| REQ-064 | `spine export` copies `visibility: client` documents into `code/docs/` and logs it | Internal documents are never exported | Should | Workspace layout |

## CRM
| ID | Requirement | Acceptance (summary) | Priority | Spec section |
| --- | --- | --- | --- | --- |
| REQ-070 | A Twenty app defines the custom objects, fields and views as code, from `taxonomy.json` | Installing the app on a fresh Twenty creates all objects and views | Must | Twenty CRM MVP |
| REQ-071 | `spine sync` upserts one way by spine id and keeps `crm-ids.json` | Running sync twice creates no duplicates | Must | Twenty CRM MVP |

## Quality attributes
| ID | Requirement | Acceptance (summary) | Priority | Spec section |
| --- | --- | --- | --- | --- |
| REQ-080 | TypeScript, current Node LTS, installed as one `spine` command | `pnpm` install from the repo gives a working `spine` binary | Must | Decisions |
| REQ-081 | The spine never calls an AI model | No model SDK in its dependencies | Must | Concept |
| REQ-082 | Every lifecycle transition has a unit test | The test suite enumerates the transition tables | Must | Build order |
| REQ-083 | Works on macOS and Linux; Windows through WSL | CI runs on both macOS and Linux | Must | Decisions |
| REQ-084 | Every command works offline except `sync` and `pr` | No network call outside those two | Should | Concept |

## Design reviews
| ID | Requirement | Acceptance (summary) | Priority | Spec section |
| --- | --- | --- | --- | --- |
| REQ-090 | The architecture `stage_exit` gate refuses unless, for the increment's tier, every topic has a `Tnn.questions.md`, a topic review and a recorded decision; every ADR has an adr review; the stage review exists; and every review finding has a Response. Tiers: S none; M topic + stage; L and the spine itself all three. A CR that changes an ADR triggers a fresh adr review | The gate check names any missing review artifact or finding without a Response and refuses; a CR that edits an ADR reopens its adr review | Should | ADR-018 |
| REQ-091 | `spine-guard` enforces the design-reviewer's blind read scope: in topic mode it cannot read `topics/Tnn.architect.md` | A design-reviewer read of the Architect's recommendation in topic mode is blocked | Should | ADR-018 |
