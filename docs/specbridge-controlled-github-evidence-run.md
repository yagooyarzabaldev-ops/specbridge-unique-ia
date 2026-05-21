# SpecBridge Controlled GitHub Evidence Run

## Purpose

This document records the first SpecBridge run that replaces branch orchestration simulation evidence with real GitHub child pull request evidence.

The run proves that a coordinator can consume real executor branch records, real child PR URLs, GitHub CI status, and ChatGPT/Codex audit status before marking integration ready.

## Controlled Scope

The run used the issue 058 executor packets and the issue 059 branch plan as source evidence.

It created one GitHub branch per executor packet:

```text
claude/issue-058-live-antigravity-executor-handoff-agent-a-implementation
claude/issue-058-live-antigravity-executor-handoff-agent-b-tests
claude/issue-058-live-antigravity-executor-handoff-agent-c-documentation
```

It opened one child PR per executor branch:

| Executor | PR | Evidence |
| --- | --- | --- |
| Agent A implementation | https://github.com/yagooyarzabaldev-ops/specbridge/pull/56 | CI passed, ChatGPT/Codex audit approved |
| Agent B tests | https://github.com/yagooyarzabaldev-ops/specbridge/pull/57 | CI passed, ChatGPT/Codex audit approved |
| Agent C documentation | https://github.com/yagooyarzabaldev-ops/specbridge/pull/58 | CI passed, ChatGPT/Codex audit approved |

The child PRs remain open as evidence records. This contract does not merge child executor PRs.

## Evidence Input

The committed GitHub evidence input is:

```text
.specbridge/github-evidence/issue-060-controlled-github-evidence-run.input.json
```

It records for each child PR:

- packet id
- branch name
- PR URL
- PR number
- PR status
- head SHA
- CI status
- CI run ids
- ChatGPT/Codex audit status

## CLI Evidence Flow

`specbridge record-github-evidence` reads the issue 059 branch plan plus declared GitHub evidence input and writes:

```text
.specbridge/branch-plans/issue-060-controlled-github-evidence-run.branch-plan.json
```

The command rejects simulation URLs in GitHub evidence mode and requires evidence packet ids and branch names to match the source branch plan.

Then `specbridge coordinate-executors -EvidenceMode github` writes:

```text
.specbridge/orchestrations/issue-060-controlled-github-evidence-run.executor-orchestration.json
```

The coordinator marks integration `ready_for_integration` only when every child result has:

- a real GitHub PR URL
- CI status `passed`
- ChatGPT/Codex audit status `approved`

## Validation

The controlled GitHub evidence run is covered by:

- `scripts/validate-branch-orchestrations.ps1`
- `scripts/test-specbridge-branch-orchestration.ps1`
- `scripts/test-specbridge-cli.ps1`
- `scripts/specbridge.ps1 validate -Profile standard`
- `scripts/test-specbridge-negative-validations.ps1`
- `scripts/specbridge-smoke.ps1`

## Runtime Boundary

This run authorizes controlled branch and child PR evidence creation only for the issue 058 executor packets.

It does not launch Antigravity sessions, start Claude Code, merge child executor PRs, create product runtime code, install dependencies, create an MCP server, create a GitHub App, add a hosted dashboard, touch production, or access protected credentials.
