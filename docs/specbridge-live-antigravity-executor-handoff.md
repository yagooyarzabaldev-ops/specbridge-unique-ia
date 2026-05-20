# SpecBridge Live Antigravity Executor Handoff

## Purpose

This document records the first runtime-preparation step after the file-backed multi-agent pilot.

SpecBridge now prepares deterministic executor handoff packets for separate Antigravity Claude Code sessions without launching those sessions from the repository.

## Handoff Model

```text
SpecBridge Coordinator
  reads declared executor slices
  validates contract and report references
  creates one executor packet per slice

Antigravity Claude Code Executor
  receives one packet
  checks contract, scope, validations, and stop conditions
  works only inside the declared branch and write scope

ChatGPT / Codex Reviewer
  audits final output against packet, contract, final report, CI, and policy
```

## CLI Command

`specbridge prepare-executors` reads a declared JSON input and writes:

```text
.specbridge/executor-packets/*.executor-packet.json
```

Each packet includes:

- task id
- slice id
- agent role
- goal
- `manual_antigravity` launch mode
- branch name
- execution contract path
- final report path
- exclusive write scope
- read-only scope
- required validations
- stop conditions
- source files

## Current Packets

The first handoff input is:

```text
.specbridge/executor-handoffs/issue-058-live-antigravity-executor-handoff.input.json
```

It generates:

```text
.specbridge/executor-packets/issue-058-live-antigravity-executor-handoff-agent-a-implementation.executor-packet.json
.specbridge/executor-packets/issue-058-live-antigravity-executor-handoff-agent-b-tests.executor-packet.json
.specbridge/executor-packets/issue-058-live-antigravity-executor-handoff-agent-c-documentation.executor-packet.json
```

## Validation

`scripts/validate-executor-packets.ps1` checks:

- required packet fields
- repository-relative paths
- `manual_antigravity` launch mode
- allowed status
- unique packet ids
- unique branch names
- existing execution contract references
- final report path shape
- declared validations
- declared stop conditions
- existing source files

`scripts/test-specbridge-executor-handoff.ps1` verifies:

- three executor packets can be generated
- generated packets validate
- duplicate branch names fail before handoff

## Runtime Boundary

This task does not launch Antigravity sessions, start Claude Code, create executor branches, open child PRs, install dependencies, create product runtime code, touch production, or access secrets.

The next milestone is real branch-per-executor orchestration from these packets.
