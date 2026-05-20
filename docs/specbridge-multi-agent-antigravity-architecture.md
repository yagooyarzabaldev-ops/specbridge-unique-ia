# SpecBridge Multi-Agent Antigravity Architecture

## Purpose

This document defines how SpecBridge should support multiple agents working in parallel inside Antigravity and Claude Code while preserving Spec Driven Development, policy enforcement, validation, review, and auditability.

Spec Driven Development is the control skeleton.

Multi-agent execution is the production model for parallel implementation.

## Core Thesis

SpecBridge must not be limited to one Claude Code worker at a time.

The product should allow several governed agents to build concurrently when their scopes are independent, explicitly contracted, and validated through GitHub.

Parallel work is allowed only when coordination is explicit.

## Operating Model

```text
User
  defines product goal

ChatGPT / Codex Governor
  decomposes the goal into specs, tasks, and acceptance criteria

SpecBridge Coordinator
  creates execution contracts, assigns scopes, tracks dependencies, and enforces policy

Antigravity Workspace
  hosts multiple Claude Code executor sessions

Claude Code Executors
  implement assigned contracts inside isolated scopes

GitHub
  validates, reviews, merges, and preserves the audit trail
```

## Required Roles

### Governor

The Governor owns intent and coherence.

Responsibilities:

- interpret user goals
- define product requirements
- split work into independent execution contracts
- decide task dependencies
- approve escalation decisions
- audit final evidence

The Governor may be ChatGPT/Codex.

### Coordinator

The Coordinator owns parallel execution safety.

Responsibilities:

- create one execution contract per agent task
- assign allowed and blocked scopes
- prevent overlapping write ownership
- track task dependencies
- detect merge conflicts
- route escalations
- assemble final reports
- decide whether a PR can enter auto-merge

The Coordinator may be SpecBridge logic, Codex, or a future local CLI/MCP tool.

### Executor

An Executor owns one bounded task.

Responsibilities:

- read assigned contract
- modify only assigned files
- run required validations
- produce final report evidence
- stop on policy or scope violation
- avoid changing another executor's owned files

An Executor may be a Claude Code session inside Antigravity.

### Reviewer

The Reviewer verifies implementation independently.

Responsibilities:

- compare changes against contract
- detect policy violations
- detect missing tests or evidence
- request changes when gates are not satisfied

The Reviewer must not be the same active execution session that produced the implementation.

## Parallel Execution Rules

Parallel execution is allowed when:

- every executor has a separate execution contract
- every contract has disjoint write scope
- shared files are either read-only or assigned to exactly one owner
- dependencies are declared before work starts
- validations are deterministic
- each executor reports evidence independently
- merge is gated by CI, review, and policy

Parallel execution must stop when:

- two executors need to write the same file
- a task requires scope expansion
- a dependency is unresolved
- acceptance criteria contradict
- a shared contract must change
- secrets, production, billing, auth security, CI/CD security, or destructive infrastructure are involved

## Scope Ownership Model

Every execution contract must define write ownership.

Ownership states:

- `exclusive_write`: only this executor may modify the path
- `read_only`: executor may inspect but not modify
- `shared_read`: multiple executors may inspect
- `coordinator_owned`: only the Coordinator may modify

Shared files such as `README.md`, root policy files, and global specs should default to `coordinator_owned` during parallel work.

## Branching Model

Preferred branch model:

- one branch per executor task for independent work
- one integration branch when tasks must be assembled before PR
- one PR per independently mergeable task
- one umbrella PR only when changes are tightly coupled

Branch names should preserve task identity:

```text
codex/<task-id>-<short-name>
claude/<task-id>-<short-name>
specbridge/<epic-id>-integration
```

## Contract Requirements For Multi-Agent Work

Multi-agent execution contracts must include:

- agent role
- task dependency list
- exclusive write scope
- read-only scope
- blocked scope
- expected output artifacts
- validation commands
- escalation route
- merge strategy
- conflict handling rule

No executor should start without a contract that names its ownership boundary.

## Antigravity Workspace Model

Inside Antigravity, each Claude Code executor should run as an isolated task session.

Each session receives:

- one execution contract
- required source references
- explicit allowed files
- explicit blocked files
- validation commands
- final report path
- escalation path

Executors must not rely on ambient chat history as authority.

## Evidence Model

Each executor must produce:

- changed file list
- validation output summary
- final report artifact
- escalation artifact if blocked
- PR link when branch is pushed

The Coordinator assembles:

- task dependency graph
- contract list
- branch list
- PR list
- validation summary
- review summary
- final integration report

## Merge Model

SpecBridge may auto-merge independent executor PRs only when:

- the active policy allows auto-merge
- all required checks pass
- no protected files changed
- no blocked scope changed
- review gate passed
- dependency order is satisfied
- the PR does not conflict with queued or merged sibling tasks

Integration branches should not auto-merge until all child task evidence is complete.

## Product Requirement

SpecBridge must treat multi-agent orchestration as a first-class product capability.

The first runtime implementation should support:

- task decomposition into multiple contracts
- write-scope conflict detection
- branch naming
- final report aggregation
- GitHub PR tracking
- blocked task escalation

Hosted dashboards, real-time collaboration UI, and cross-repository scheduling remain future work.

