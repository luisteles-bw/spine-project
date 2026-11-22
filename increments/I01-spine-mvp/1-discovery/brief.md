---
id: I01-BRIEF
type: brief
title: I01 Spine MVP brief
increment: I01
stage: discovery
parent: I01
status: approved
version: 1
refs: [SPEC, CONCEPT, REQUIREMENTS, SECURITY]
visibility: internal
author: architect
updated: 2026-11-22
---

## Goal
A working spine you can use on your first client project: from `spine init` with the
`nextjs-static` profile to a merged phase PR, driven only by spine commands, with gates no agent
can pass, and project state visible in Twenty.

## In scope
- Everything marked **Must** and **Should** in `REQUIREMENTS`.
- The `nextjs-static` profile only.
- The Twenty app (objects, fields, views) and one-way `spine sync`.
- The switch from this bootstrap's `STATE.md` to the spine's own event log.

## Out of scope
- The other four stack profiles (each is built when a project needs it).
- Everything listed as V2 or Later in the spec's "Feasible for MVP vs later" table.

## Success measures
1. A sample `nextjs-static` project goes from `spine init` to a merged phase PR using only spine
   commands and the slash commands.
2. From Claude Code's shell, `spine approve` fails, and edits outside a task's scope are blocked.
3. Replaying the same event log twice produces an identical `graph.json`.
4. `spine check --trace` reports no gaps for I01 itself.

## Risks and assumptions
| Risk or assumption | Effect if wrong | Mitigation |
| --- | --- | --- |
| You build the tool while selling and delivering December work | The spine is late or half-done when a client signs | Reach the switch-over early; the bootstrap mode works for a client project in an emergency |
| Claude Code's agent, hook or settings formats change | Agents or the guard stop working | Keep the Claude assets thin and version them in `code/claude/`; check the docs at each phase |
| Twenty's app SDK is younger than the core product | The CRM phase takes longer | Keep it last among the Must phases; plain API calls are the fallback |
| The environment variable used to detect an agent shell isn't reliable | SEC-001 is weaker than intended | The guard hook blocks `spine approve` as a second layer |

## Questions for the architecture session
Work through these in order. Each needs a decision; most need an ADR.

1. **Packaging.** One package, or a small monorepo (core, CLI, Twenty app, templates)? How is
   `spine` installed on your machine: `pnpm link`, a private npm package, or a release tarball?
2. **Toolchain.** Node LTS version, ESM, build tool (tsup, tsdown or tsc), how to run during
   development (tsx), lint and format (ESLint + Prettier, or Biome).
3. **CLI framework.** Which argument parser, and how `--json` output and exit codes are standardised.
4. **Schemas.** Zod as the source with JSON Schema exported, or JSON Schema first? Error format
   for agents.
5. **Documents.** Frontmatter parser, Markdown parsing for required headings, id-to-path index,
   reference resolution.
6. **Event log and state.** Event shape and ids, append-only writes, single-writer locking,
   rebuilding `graph.json`, record hashes, recovery from a corrupt line.
7. **Lifecycles.** Transition tables as typed data plus a pure reducer? How gates from
   `spine.yaml` attach to transitions.
8. **Context assembly.** The reading list per role and step; size limits.
9. **Git.** Shell out to `git` with argument arrays, or a library? Producing commits with trailers.
10. **Guard hook.** Claude Code's PreToolUse input, how the guard learns the active role and task
    scope, and a speed budget (it runs on every tool call).
11. **Checks and secrets.** Process spawning, timeouts, output capture and redaction; keychain
    access on macOS and Linux.
12. **Agent-shell detection.** Which environment variable Claude Code sets in its shell (verify
    in the current docs), plus the guard as a second layer.
13. **Profiles.** How `spine init` runs the official scaffolder and applies the contract;
    `nextjs-static` specifics; where MCP configuration comes from.
14. **Twenty.** App layout inside the repo, REST or GraphQL for sync, id mapping, rich text
    Markdown, rate limits.
15. **Testing the spine.** Unit tests for the core, integration tests with temporary directories
    and real git, and one end-to-end run on a fixture project.
16. **Switch-over.** How `STATE.md` is imported, and how `.claude/commands/` change afterwards.
17. **OS support.** Confirm macOS and Linux first, with Windows through WSL.

## Suggested phase outline (for the Architect to challenge)
| Phase | Goal |
| --- | --- |
| P01 | Repo, toolchain and CI for the spine itself |
| P02 | Schemas, templates, frontmatter parsing, id index |
| P03 | Event log, graph and the five lifecycles: the pure core |
| P04 | CLI core: status, next, context, submit, approve and reject, session, plan apply; then the switch-over |
| P05 | Claude assets in `code/claude/` and the guard hook |
| P06 | check, git automation, pr, changelog |
| P07 | `spine init` and the `nextjs-static` profile |
| P08 | Twenty app and `spine sync` |
| P09 | Change requests, split and cut, increments, tickets, time, export |
| P10 | Quality: a dogfood run on a sample client project, then fixes |
| P11 | Delivery: v0.1.0 release and install guide |
