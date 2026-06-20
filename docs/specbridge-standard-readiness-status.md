# SpecBridge Standard Readiness Status

## Overview

`specbridge-standard-readiness` is a deterministic local status command for deciding whether SpecBridge is ready to start or continue standard governed work.

It aggregates existing repository evidence instead of replacing it:

- `specbridge-doctor -FixPlan -Offline`
- `specbridge-next-task`
- `specbridge-repository-health-summary`
- `specbridge-token-governance-status`
- `specbridge-mcp-resources`

The command is an operator readiness snapshot. It does not launch Claude Code, launch Codex, call the network, mutate GitHub, read secrets, change billing, enforce cleanup, enforce retention, change CI/CD security, or deploy.

## Usage

```powershell
# Emit readiness JSON to stdout only
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 specbridge-standard-readiness

# Write the governed readiness artifact
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 specbridge-standard-readiness `
  -OutputPath .specbridge/standard-readiness/current.status.json `
  -Force
```

When `-OutputPath` is omitted, no repository file is written. When `-OutputPath` is provided, the only allowed path is `.specbridge/standard-readiness/current.status.json`.

## Readiness Values

| Value | Meaning |
|-------|---------|
| `ready_for_governed_task_intake` | Doctor is healthy, no eligible task is waiting, and the next standard action is to create a governed task. |
| `continue_current_goal` | The repository has an active current goal and ordinary work should continue under that contract. |
| `execute_eligible_task` | A task is eligible in repository evidence and should be executed before creating a new one. |
| `review_recommended` | No hard blocker exists, but the aggregate posture is not the clean new-task intake state. |
| `blocked` | A policy, health, governance, or read-only boundary is not satisfied. |

## Output Shape

The command returns:

- `task_selection` - current goal status, active task, eligible count, excluded issue count, and recommended next action.
- `doctor` - offline doctor health, action count, blocker count, warning count, and online-check posture.
- `repository_health` - branch and artifact debt counts plus cleanup and enforcement posture.
- `token_context_governance` - provider source count, budget posture, turn posture, and blocked disclosure count.
- `mcp_resource_surface` - MCP server status, read-only policy, resource count, and resource URIs.
- `standard_boundaries` - explicit false values for Claude/Codex launches, network calls, GitHub mutation, secret access, billing, CI/CD security changes, deployment, cleanup permission, and retention enforcement.
- `evidence_sources` - repository files used by the aggregate.

## Operator Use

Run this command before creating a new governed operator task.

If readiness is `ready_for_governed_task_intake`, the next safe action is a normal SpecBridge intake or a dedicated execution contract.

If readiness is `continue_current_goal` or `execute_eligible_task`, do not create a new competing task. Continue or execute the existing repository-backed work first.

If readiness is `blocked`, inspect the doctor, policy, and boundary fields before proceeding.

## Boundaries

This command does not activate the blocked maintenance areas:

- branch cleanup remains disabled
- artifact retention enforcement remains disabled
- MCP server runtime remains not implemented
- production deployment remains disabled
- secrets, provider tokens, billing, auth, database, and CI/CD security changes remain blocked
