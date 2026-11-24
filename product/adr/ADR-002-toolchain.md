---
id: ADR-002
type: adr
title: Toolchain — Node 24 LTS, ESM, tsdown, ESLint + Prettier, tsx
stage: architecture
status: accepted
superseded_by:
version: 3
refs: [REQ-080, REQ-082, REQ-083, REQ-010]
visibility: internal
author: architect
updated: 2026-11-24
---

## Context

`conventions.md` fixes TypeScript strict, ESM, pnpm, the current Node LTS and Vitest. This ADR picks
the remaining tools. Three forces decide the open choices: the CLI must ship as one bundled binary
(REQ-080) and the guard — which runs on **every** agent tool call — must start fast; event-log writes
must not be silently dropped (type-aware linting); and the core→adapter purity boundary from ADR-001
must be enforceable by the linter.

## Options

| Choice | Options | Decision |
| --- | --- | --- |
| Build | `tsdown` (maintained, Rolldown) · `tsup` (now unmaintained, its README points to tsdown) · `tsc` (zero-dep, multi-file) | **tsdown**, version pinned |
| Lint/format | ESLint + Prettier (type-aware) · Biome (fast, GritQL can ban `new Date()` too) | **ESLint + Prettier** |
| Dev run | `tsx` · Node 24 native type-stripping · run built JS | **tsx** now, migration-ready to native stripping |

## Decision

- **Runtime:** Node 24 (Active LTS), pinned via `.nvmrc` + `engines`. Pure ESM (`"type": "module"`).
- **TypeScript:** strict, plus **`erasableSyntaxOnly`** and **`verbatimModuleSyntax`** from the start,
  so the code stays compatible with Node 24's built-in type stripping and `tsx` can be dropped later.
- **Build: `tsdown`** (pinned). `tsup` is no longer maintained and its README now recommends tsdown,
  making tsdown the "boring", maintained choice. Bundling to a single file keeps the guard hook fast
  (it spawns on every tool call) and keeps the tarball self-contained.
- **Lint/format: ESLint + Prettier.** Chosen for **typescript-eslint's type-aware rules** —
  especially `no-floating-promises` protecting event-log writes — and for the core→adapter import
  boundary rule. (Biome 2 *can* ban `new Date()` via GritQL plugins, so that is not the deciding
  factor; the type-aware rules are.)
- **Dev run: `tsx`** for the `pnpm spine` / `spine-dev` loop; the tsdown bundle powers the stable
  tarball.
- **Tests:** Vitest.

## Consequences

- **Easier:** single-file bundle → fast guard and a clean, self-contained tarball; type-aware lint
  catches dropped promises in state writes; the code stays migration-ready to native type stripping.
- **Harder:** tsdown is younger than `tsc` (pin it; it is a `new_dependency` gate); type-aware
  ESLint is slower than Biome and needs a typed lint config; `erasableSyntaxOnly` forbids enums,
  namespaces and parameter properties — use plain unions and `const` objects instead.
- **Must now be true:** the toolchain phase pins Node 24, sets ESM and the three tsconfig flags, adds
  tsdown / tsx / eslint / prettier through `new_dependency` gates, and runs `pnpm spine` via `tsx`
  with the tsdown bundle as the stable artifact. Phases: see `I01-PLAN`'s ADR→phase table.
- **Amended 2026-11-23:** phase numbers removed.
- **Amended 2026-11-24:** visibility → internal (every spine ADR is internal; ADR-018).
