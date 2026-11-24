---
id: ADR-011
type: adr
title: Checks & secrets — sandbox-runtime containment, direct tool invocation, keychain + layered redaction
stage: architecture
status: accepted
superseded_by:
version: 2
refs: [REQ-040, REQ-041, SEC-005, SEC-006]
visibility: internal
author: architect
updated: 2026-11-23
---

## Context

`spine check` runs the configured commands and writes `checks.json` (REQ-040); secrets come from the
OS keychain and reach only the check child (REQ-041, SEC-006); known secret values are redacted from
output and never reach events/logs/Twenty (SEC-005). The spine runs outside the sandbox (ADR-006) but
must contain the project code a check runs. Targets macOS and Linux, Windows via WSL (REQ-083).

## Decision

### Containment — `@anthropic-ai/sandbox-runtime`
- Spine wraps each check with **`@anthropic-ai/sandbox-runtime`** (Apache-2.0, the sandbox Claude Code
  uses), **pinned** — it's a research preview (`new_dependency` gate). No hand-written Seatbelt/bwrap
  profiles. Missing Linux dependencies → the environment check fails (exit 3).
- **Network is denied by default**, opened per check with a **domain allowlist from the stack profile**
  (e.g. a Sanity build needs the Sanity API host; `next/font/google` downloads fonts at build).
- **Least-privilege secrets per check:** `spine.yaml` names which secrets each check gets — `test` gets
  **none**; only `build` gets the CMS read token.
- **Post-check secret sweep:** after each check, spine searches changed + untracked files (including
  build output) for the **exact injected values**; a hit **fails the check**. This catches a test that
  writes a secret to a file for an agent to read, and a server secret accidentally bundled into the
  static site.
- **Verification:** a test asserts a sandboxed check **cannot read the keychain** (`security
  find-generic-password` must fail inside it). If it can, this ADR needs another answer.

### Check commands — direct tools, not package.json scripts
- argv arrays in `spine.yaml`, spawned via `execFile` (no shell, SEC-009), but **calling tools
  directly** — `["pnpm","exec","vitest","run"]`, `["pnpm","exec","eslint","."]`,
  `["pnpm","exec","tsc","--noEmit"]` — **never package.json scripts**, because `["pnpm","test"]` runs a
  coder-editable script that could be `exit 0`. (The four human/CI scripts still exist per REQ-002; the
  spine simply doesn't trust them. This deviates from the spec's "spine runs `pnpm lint/test/…`".)
- **Check configs** (`package.json`, the lockfile, vitest/eslint/tsconfig) are in **every coder task's
  `forbid`** by default; changing them needs the plan or a CR.
- The test check uses **Vitest's JSON reporter**, so `checks.json` records which tests passed; **submit
  requires a passing `AC-n` test for each acceptance criterion** (a skipped test is not a pass).

### Secrets — keychain adapter + layered redaction
- One keychain adapter: `security` (macOS) / `secret-tool` (Linux). On **Linux without a Secret
  Service** (common on WSL), fall back to a **0600 file outside the workspace**, covered by a Read deny
  and sandbox `denyRead`. CI uses its own env secret store.
- Secrets are injected **only** into the check child's env; **Bash deny rules for `security` and
  `secret-tool`** keep agents out of the keychain (the guard allowlist also blocks them, ADR-010).
- **Redaction:** replace the exact injected values **and their base64 + URL-encoded forms** with `***`;
  redact the **full captured output before summarising** (so a value split across stream chunks can't
  slip through); **refuse secret values shorter than 8 characters** at setup (redacting them would
  mangle normal output).

## Consequences

- **Easier:** project code runs contained without hand-rolled profiles; per-check least-privilege + the
  post-check sweep close the "write a secret to a file" path; checks can't be faked by editing
  package.json; redaction covers encodings and chunk splits.
- **Harder:** `@anthropic-ai/sandbox-runtime` is a pinned research-preview dependency (gate; API may
  change); per-check network allowlists and secret maps live in the profile; the WSL no-keyring fallback
  and the keychain Bash denies are more human-applied settings; checks call tools directly (a deliberate
  deviation from the spec's "runs pnpm scripts").
- **Must now be true:** `new_dependency` gate for `@anthropic-ai/sandbox-runtime`; profiles declare each
  check's direct tool argv + network allowlist + secret map; coder task templates default-forbid the
  check configs; the checks/secrets phase builds the check runner (sandbox wrap, injection, sweep,
  redaction, Vitest JSON, keychain adapter + WSL fallback) and the keychain-unreadable test; the human
  adds the `security` / `secret-tool` Bash denies (plan table). Phases: see `I01-PLAN`'s ADR→phase table.
- **Amended 2026-11-23:** phase numbers removed; visibility → internal.
