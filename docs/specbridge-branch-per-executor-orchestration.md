# SpecBridge Branch Per Executor Orchestration

## Purpose

This document records the runtime layer after Antigravity executor handoff packets.

SpecBridge now maps executor packets to independent executor branches and coordinator evidence records. The layer supports simulation for local product testing and GitHub evidence mode for real executor PRs.

## Branch Plan Model

```text
Executor packets
  declare contract, branch name, write scope, validations, and final report path

Branch plan
  creates one executor branch record per packet
  tracks PR URL, PR status, CI status, ChatGPT audit status, and rollback notes

Coordinator orchestration
  aggregates child executor evidence
  blocks integration until every child PR has real passing evidence
```

## CLI Commands

`specbridge plan-executor-branches` reads executor packets and writes:

```text
.specbridge/branch-plans/*.branch-plan.json
```

The branch plan records:

- one branch per executor packet
- base branch
- execution contract path
- final report path
- exclusive write scope
- required validation commands
- PR status and PR URL placeholders
- CI status
- ChatGPT audit status
- rollback notes per executor branch

`specbridge coordinate-executors` reads a branch plan and writes:

```text
.specbridge/orchestrations/*.executor-orchestration.json
```

The orchestration records child executor evidence and the integration decision.

## Evidence Modes

### Simulation

Simulation mode is for testing the product loop without launching Antigravity sessions or opening child PRs.

Simulation records use `simulation://` PR URLs and simulated CI/audit statuses. They always set `merge_allowed` to `false`, and the integration decision is `simulation_only_no_merge`.

### GitHub

GitHub evidence mode is for real executor PRs.

The coordinator can mark integration ready only when every child executor has:

- a real GitHub PR URL
- CI status `passed`
- ChatGPT audit status `approved`

If any child is missing evidence, the coordinator marks the integration as blocked.

## Current Artifacts

The first branch plan is:

```text
.specbridge/branch-plans/issue-059-branch-per-executor-orchestration.branch-plan.json
```

It maps the issue 058 executor packets to three planned executor branches:

```text
claude/issue-058-live-antigravity-executor-handoff-agent-a-implementation
claude/issue-058-live-antigravity-executor-handoff-agent-b-tests
claude/issue-058-live-antigravity-executor-handoff-agent-c-documentation
```

The first coordinator artifact is:

```text
.specbridge/orchestrations/issue-059-branch-per-executor-orchestration.executor-orchestration.json
```

It is simulation-only and cannot authorize merge.

## Validation

`scripts/validate-branch-orchestrations.ps1` checks:

- branch plan required fields
- one executor branch record per packet
- unique packet ids
- unique branch names
- repository-relative paths
- existing contract references
- required validation commands
- rollback notes
- orchestration required fields
- simulation evidence boundaries
- GitHub PR URL shape in GitHub evidence mode

`scripts/test-specbridge-branch-orchestration.ps1` verifies:

- branch plans can be generated from executor packets
- coordinator simulation artifacts can be generated
- branch orchestration artifacts validate
- duplicate branch names fail before orchestration
- simulation evidence cannot authorize merge

## Runtime Boundary

This task does not launch Antigravity sessions, start Claude Code, create live executor branches, open child PRs, install dependencies, create product runtime code, touch production, or access protected credentials.

The next runtime milestone is a controlled GitHub evidence run where child executor branches and PRs are created by an explicitly authorized contract, then coordinated in GitHub evidence mode.
