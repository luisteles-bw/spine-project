---
id: ADR-009
type: adr
title: Git & PR automation — real git via arg arrays, hook-proof, gh CLI, tamper-proof phase_pr
stage: architecture
status: accepted
superseded_by:
version: 2
refs: [REQ-042, REQ-043, SEC-009, SEC-002]
visibility: internal
author: architect
updated: 2026-11-23
---

## Context

The spine is the only git writer, across `code/` (phase branches, per-task commits, phase PRs) and
`project/` (one `main`, a commit after every transition — the second audit trail). It runs git
**outside the sandbox** (ADR-006), so git must never execute working-tree code on its behalf. Commits
must stay trailer-searchable (REQ-042), PR/merge detection must be tamper-proof (ADR-007's `phase_pr`),
and the spine must never build shell strings (SEC-009).

## Decision

### Git access — shell out to real git (argument arrays)
- `execFile('git', [...])` with argument arrays; no shell string (SEC-009); no git library.
- **Never run working-tree code:** every call passes `-c core.hooksPath=/dev/null -c core.fsmonitor=false`,
  so a husky-style hook can't run with the spine's unsandboxed access.
- **Deterministic & non-interactive:** `LC_ALL=C`, `GIT_TERMINAL_PROMPT=0`; parse only porcelain / `-z`
  output.
- **Explicit staging:** stage only the task scope's paths — never `git add -A`; any change outside
  scope makes `submit` refuse.
- **Trailers** via git's `--trailer` flags (`Task`, `Attempt`, `Ticket`, `CR`); `project/` transition
  commits also carry `Spine-Seq: <n>` to cross-check git history against the event log.
- **Slug/id validation** against a strict pattern before any ref is formed (SEC-009).
- **Write protection:** from switch-over, `code/.git` gets the same `denyWrite` as `project/.git`
  (ADR-006), so only the spine writes git objects and `git -C code …` prefix tricks can't bypass the
  deny rules. Agents keep **read-only** git with `GIT_OPTIONAL_LOCKS=0` so `git status` won't write.
- **Floor:** git ≥ 2.32 (for `--trailer`); check at startup, exit 3 if older.

### PR + merge detection — gh CLI (argument arrays)
- `gh` reuses `gh auth` from the keychain (no token handling, security.md): `gh pr create` opens the PR,
  `gh pr view --json state,mergedAt,mergeCommit` reads state.
- **Permission model:** Claude Code's rules only see `spine …`, so git/gh the spine runs internally
  bypass the normal `gh`/push ask rules. Therefore the **`spine pr` subcommand itself goes in `ask`**;
  read-only status subcommands stay allowed.
- **Push policy:** push **phase branches only**, **never `--force`**.
- **Merge-commit only:** on repo creation, disable squash and rebase merges
  (`gh repo edit --enable-squash-merge=false --enable-rebase-merge=false`) — a squash merge would drop
  the per-task commits and their trailers (REQ-042).
- **Branch protection is conditional on the GitHub plan.** On **Free**, rulesets/branch protection don't
  exist for **private** repos, so the spine does not require them; integrity rests on the `phase_pr`
  SHA + ancestry check (which needs no server-side rule) and the merge-method settings (which work on
  Free). On **Pro/Team** the spine also sets required-status-checks + no-force-push.
- **Tamper-proof `phase_pr`:** the gate counts only if the PR's final head SHA **equals the SHA
  approved at phase review** and that SHA is an **ancestor of the base branch**
  (`git merge-base --is-ancestor`). This rejects squash merges and any commits pushed after review
  (strengthens ADR-007).

## Consequences

- **Easier:** real-git fidelity in tests; injection-proof and hook-proof git; trailer-searchable history
  cross-linked to the log via `Spine-Seq`; a `phase_pr` gate that squash or post-review pushes can't
  fool.
- **Harder:** we parse porcelain ourselves; repo setup disables squash/rebase (and, on Pro/Team, sets
  branch protection); `spine pr` → `ask` (baseline) and `code/.git` → denyWrite (switch-over) are
  human-applied settings (plan table); git ≥ 2.32 is a hard floor.
- **Must now be true:** the git + gh adapters are built in the git/PR phase (hooks disabled, explicit
  staging, `--trailer`, `Spine-Seq`, merge-base ancestry check, version floor); init disables
  squash/rebase and sets merge-commit-only (branch protection only on Pro/Team); `spine pr` is in `ask`
  from the **baseline** settings and `code/.git` joins denyWrite at switch-over. Phases: see `I01-PLAN`'s
  ADR→phase table.
- **Amended 2026-11-23:** `spine pr` ask is baseline (not switch-over); branch protection made
  conditional on the GitHub plan (Free has none for private repos); phase numbers removed; visibility →
  internal.
