---
id: CONCEPT
type: concept
title: Spine concept
stage: discovery
status: approved
version: 1
refs: [SPEC]
visibility: internal
author: architect
updated: 2026-11-22
---

## Problem
AI coding agents are fast but unreliable without structure. Left alone they skip steps, grade
their own work, drift from the agreed scope and leave no record a client or a future developer can
trust. For a one-person agency, that turns every project into supervision work.

## What the spine is
A TypeScript CLI that runs a software project through fixed lifecycles. It decides the next step,
hands it to the right agent with exactly the right context, validates what comes back, and stops
at every decision that belongs to a human. Everything it does is recorded as documents and events.

The rule: **the spine decides, agents do the work, the human approves, the CRM displays.**

## Users
- **The engineer** (you): works at the keyboard in VS Code with Claude Code, approves gates,
  reviews PRs.
- **Agents**: Architect, Tester, Coder, Verifier, Security, each with a narrow job and limits.
- **Twenty CRM**: receives a one-way copy of project state and documents for tracking.

## Goals for the MVP
1. Run a real client project from discovery to delivery and support with the spine.
2. Make gates impossible for an agent to pass.
3. Produce a complete, traceable record: requirement to task to test to commit to PR.
4. Collect the estimate-versus-actual data that later powers estimates and proposals.

## Non-goals for the MVP
- Unattended or parallel runs, Docker sandboxes, a VS Code extension.
- Two-way CRM sync, a client portal, a Gantt view, billing reports.
- Calling AI model APIs from the spine. The spine never calls a model; Claude Code does.

The full concept, with every decision behind it, is `SPEC` (`project/product/spec.md`).
