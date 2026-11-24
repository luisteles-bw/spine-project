---
id: ADR-001
type: adr
title: One workspace-ready package with a compile-isolated pure core
stage: architecture
status: accepted
superseded_by:
version: 2
refs: [REQ-080, REQ-082, SEC-001]
visibility: client
author: architect
updated: 2026-11-23
---

## Context

`conventions.md` requires a **pure core** — no file system, git, clock, environment or randomness
inside it — so that every lifecycle transition is unit-tested without adapters (REQ-082) and a
replay of the event log always rebuilds the same `graph.json` (REQ-010). The spine must also install
as a single `spine` command (REQ-080). This is a solo build over about three weeks, so tooling
should stay minimal. Two further facts shape packaging: the Twenty app (built late) is a separate Twenty
SDK deployable, and the guard hook runs on every agent tool call, so the `spine` it calls must not
be weakened by the spine code you are currently editing.

## Options

| Option | Pros | Cons |
| --- | --- | --- |
| A. Single package, workspace-ready | Least tooling; one build and one `bin`; purity enforced by tsconfig + ESLint; `twenty-app` can join the pnpm workspace later | Core purity rests on config, not a hard package boundary |
| B. Full monorepo now | Hard `@spine/core` / `@spine/cli` boundaries; core cannot import an adapter | tsconfig project references, build ordering and inter-package versioning — real ceremony up front |
| C. Single package, no workspace | Simplest possible | `twenty-app` becomes a messy retrofit later |

## Decision

**Option A**, with these specifics:

- **Compile-isolated core.** `src/core/` has its own `tsconfig.json` with `"types": []` so Node and
  DOM built-ins do not resolve there — touching `fs`, `process` or `Date` in core fails typecheck,
  not just lint. An ESLint rule additionally bans `Date.now()`, argument-less `new Date()` and
  `Math.random()` under `src/core/**`. Time, randomness and id generation enter core as injected
  ports.
- **Workspace.** A pnpm workspace holds one package now. `twenty-app` joins as a second package in
  later **only if** Twenty's tooling tolerates being a workspace member (verify then); otherwise it is
  a sibling package with its own install.
- **Escape hatch.** If boundary violations recur despite tsconfig + ESLint, promote `core` to its
  own package `@spine/core`.

**Run and install model** (how `spine` is invoked):

- **Bootstrap → switch-over:** nothing is installed globally. Invoke through a root script,
  `pnpm spine <command>`.
- **From the switch-over:** the daily `spine` is a global install from a `pnpm pack` tarball of
  the **last merged phase**. Keep the last two or three tarballs for rollback.
- The working copy runs as a separate **`spine-dev`** alias pointing at the repo's build output. No
  `pnpm link --global`, which would hijack the `spine` command name.
- The guard hook in `.claude/settings.json` always calls the **stable** `spine`, so editing the
  guard's own code never weakens the active session.
- **Versions:** `0.1.0-dev.N`, bumped at each merged phase; `0.1.0` at P11. No private npm registry
  until a second machine or user needs one.

## Consequences

- **Easier:** coding starts immediately; core purity is a compile error; dogfooding is safe because
  stable `spine` and `spine-dev` are different commands; rollback is reinstalling a kept tarball.
- **Harder:** a second `src/core/tsconfig.json` and ESLint boundary config must be maintained; each
  merged phase must build → pack → reinstall the stable `spine` (automate at release); `twenty-app`
  workspace membership stays open until the Twenty phase.
- **Must now be true:** all clock, randomness and id generation are injected ports into core. The
  toolchain phase sets up the workspace, the dual tsconfig, the ESLint boundary rules, the `pnpm spine`
  script and version `0.1.0-dev.0`; the switch-over adds the pack + global-install step and the
  `spine-dev` alias; the guard phase wires the guard to the stable `spine` path. Phases: see `I01-PLAN`'s
  ADR→phase table.
- **Amended 2026-11-23:** phase numbers removed.
