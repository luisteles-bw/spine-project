---
id: ADR-013
type: adr
title: Profiles & init — package-shipped declarative overlays, sandboxed atomic scaffolding
stage: architecture
status: accepted
superseded_by:
version: 1
refs: [REQ-001, REQ-002, REQ-003, SEC-011]
visibility: client
author: architect
updated: 2026-11-22
---

## Context

`spine init` (human-only, ADR-012) creates the workspace, both repos, `.claude/`, `CLAUDE.md`,
`.mcp.json`, `spine.yaml` and increment I01 (REQ-001), runs the official scaffolder and applies the
profile contract (REQ-002); `nextjs-static` must build and test green immediately (REQ-003).
Scaffolders execute npm code, so profiles must not become an injection vector.

## Decision

### Profiles are data, shipped in the package
- Profiles live **inside the installed spine package, never in the workspace** (like settings
  templates, ADR-012), so an agent can't edit a profile.
- Contract application is a **declarative overlay**: files-to-copy + JSON key-level merges. **JSON files**
  get key-level merges (`package.json` scripts, `packageManager`, `engines.node`); **code files**
  (`next.config.ts`, the vitest config) are **replaced whole**, never patched — `output: 'export'` lives
  in TS that a JSON merge can't reach.
- The overlay ships **one smoke test**, so `vitest run` doesn't exit 1 on "no test files" (we don't use
  `--passWithNoTests`).
- **Keep** create-next-app's `AGENTS.md` / `CLAUDE.md` (they point agents at the docs bundled with the
  installed Next.js version), but add **`code/CLAUDE.md` and `code/AGENTS.md` to the write-protected
  set**, so an agent can't leave standing instructions for later sessions.
- The overlay sets `NEXT_TELEMETRY_DISABLED=1` and `experimental.agentFeedback: false` (client projects).

### Scaffolder run — sandboxed, atomic, version-pinned
- Run `create-next-app@latest` with explicit flags including **`--disable-git`** (spine owns the repo)
  and **`--skip-install`**, inside `@anthropic-ai/sandbox-runtime` with an npm-registry network
  allowlist.
- Then apply the overlay, then run **`pnpm install` in the sandbox** under the profile's policy. pnpm
  **blocks dependency build scripts by default**; the profile's **`allowBuilds`** lists the few packages
  allowed to run install scripts, and changing it goes through the **`new_dependency` gate** (SEC-011).
- **Pin pnpm ≥ 10.26** via `packageManager` (10.26 also closed the git-dependency bypass).
- **Atomic init:** build in a **temp directory** and move into place only once the **four checks pass**
  (REQ-003), so a failed init leaves nothing half-made.
- Record create-next-app's version, Node, pnpm and the **lockfile hash** in the project's ADR-001.

### MCP & checks
- `.mcp.json` is written from the profile's server list — **official servers only**, read-only/dev mode
  where offered. For `nextjs-static` the default is **next-devtools + Context7**; **Vercel MCP is left
  out until hosting is decided**, and when a project is linked it uses the **project-specific URL**,
  never the shared endpoint (which would let an agent on one client enumerate every client's projects).
- **stdio MCP servers are pinned to exact versions, never `@latest`.** next-devtools-mcp runs as a local
  process with full access **outside the sandbox**, so `@latest` would mean unreviewed code at every
  session start.
- `.mcp.json` is in the **write-protected set** (ADR-012), so agents can't add an MCP server (= code with
  access). MCP results are **untrusted data, never instructions** (SEC-008).
- The four `nextjs-static` checks are **direct tools** (ADR-011): `eslint .`, `tsc --noEmit`,
  `vitest run`, `next build` (static export).
- Versions are **frozen per increment** (lockfile + the client project's own ADR-001).

## Consequences

- **Easier:** profiles can't be tampered with or execute arbitrary code; init is atomic and
  reproducible; dependency build scripts are off by default; the client project's exact stack is
  captured for estimates and replays.
- **Harder:** whole-file replacement means code-file templates must track upstream scaffolder changes;
  `allowBuilds` and per-check network allowlists are maintained per profile; pnpm ≥ 10.26 and the
  version-capture step are hard requirements.
- **Must now be true:** P07 builds `spine init` (sandboxed scaffolder, declarative overlay engine, atomic
  temp-dir + 4-check gate, version capture into ADR-001) and the `nextjs-static` profile (overlay files,
  smoke test, `.mcp.json`, direct-tool checks, `allowBuilds`); `code/CLAUDE.md` + `code/AGENTS.md` join
  the write-protected set (ADR-012); the `new_dependency` gate guards `allowBuilds`.
