# SpecBridge Final Standardization Status

## Overview

`specbridge-final-standardization-status` is a deterministic read-only CLI command that produces a final standardization evidence snapshot before serious product-build pilots.

It aggregates the same evidence sources used by `specbridge-standard-readiness` and adds:

- `standardization_completion_pct` — estimated governed infrastructure completeness
- `remaining_standardization_pct` — estimated remaining policy-gated or pilot-gated work
- `remaining_gaps` — policy-gated or pilot-gated areas grouped by category
- `blocked_boundaries` — permanently blocked actions under current policy
- `recommended_next_contracts` — advisory next governed tasks with activation gates
- `validation_expectations` — the full local validation suite for this repository

The command is deterministic. It does not launch Claude Code, launch Codex, call the network, mutate GitHub, read secrets, change billing, enforce cleanup, enforce retention, change CI/CD security, or deploy.

## Usage

```powershell
# Emit final standardization status JSON to stdout only
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 specbridge-final-standardization-status

# Write the governed status artifact
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 specbridge-final-standardization-status `
  -OutputPath .specbridge/standard-readiness/final-standardization.status.json `
  -Force
```

When `-OutputPath` is omitted, no repository file is written. When `-OutputPath` is provided, the only allowed path is `.specbridge/standard-readiness/final-standardization.status.json`. `-Force` is required when that file already exists.

## Standardization Completion

| Field | Meaning |
|-------|---------|
| `standardization_completion_pct` | Integer 0–100 reflecting governed infrastructure completeness. A value of 95 means the remaining 5% is policy-gated, not missing. |
| `remaining_standardization_pct` | Integer 0–100 reflecting the estimated remaining standardization work. It complements `standardization_completion_pct`; together they total 100. |
| `remaining_gaps` | Categorized gaps where execution is pending, policy-gated, blocked by default, or waiting for a product decision. These are not silent unknowns. |
| `blocked_boundaries` | Actions that current policy prohibits entirely. These are not missing features; they are deliberately blocked. |
| `recommended_next_contracts` | Advisory contract slugs to consider after the current active scope closes. Each includes an activation gate. |

## Readiness Values

Inherited from `specbridge-standard-readiness`:

| Value | Meaning |
|-------|---------|
| `ready_for_governed_task_intake` | Doctor is healthy, no eligible task is waiting, and the next standard action is a new governed intake. |
| `continue_current_goal` | The repository has an active current goal; continue under that contract. |
| `execute_eligible_task` | A task is eligible in repository evidence; execute it before creating a new one. |
| `review_recommended` | No hard blocker, but the aggregate posture is not the clean new-task intake state. |
| `blocked` | A policy, health, governance, or read-only boundary is not satisfied. |

## Output Shape

- `standardization_completion_pct` — integer, 0–100
- `remaining_standardization_pct` — integer, 0–100
- `readiness` — inherited readiness value
- `recommended_next_action` — next task selector recommendation
- `remaining_gaps` — array of `{ category, gap, status, gate }`
- `blocked_boundaries` — string array of permanently blocked actions
- `recommended_next_contracts` — array of `{ contract_slug, description, gate }`
- `validation_expectations` — string array of required local validations
- `task_selection` — current goal, eligible count, excluded count, recommended action
- `doctor` — offline doctor health, action count, blocker count, warning count
- `repository_health` — branch and artifact debt counts, cleanup and enforcement posture
- `token_context_governance` — provider sources, budget posture, turn posture
- `mcp_resource_surface` — MCP server status, read-only policy, resource count
- `standard_boundaries` — explicit false values for all mutation-capable operations
- `evidence_sources` — repository files read by this command
- `notes` — plain-language interpretation guide

## Operator Use Before a Serious Pilot

Run this command before creating a new serious product-build pilot contract:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 specbridge-final-standardization-status
```

Inspect the output:

1. `standardization_completion_pct` should be ≥ 90 for a healthy pre-pilot posture.
2. `readiness` should be `ready_for_governed_task_intake` or `continue_current_goal`.
3. `standard_boundaries` should confirm all mutation flags are false.
4. `remaining_gaps` and `blocked_boundaries` document what is deliberately not active, including serious pilot execution, repository hygiene, artifact hygiene, mutation-capable MCP, and hosted runtime.
5. `recommended_next_contracts` lists the next advisory work items after current scope closes: serious product-build pilot, PR-state-aware branch cleanup, artifact retention activation, mutation-capable MCP tools, and hosted/network MCP runtime.

If `readiness` is `blocked`, resolve the blocking condition reported in `doctor` or `repository_health` before proceeding.

## Boundaries

This command does not activate the blocked areas:

- branch cleanup remains disabled
- artifact retention enforcement remains disabled
- network MCP transport remains not implemented
- hosted MCP server deployment remains not implemented
- secrets, provider tokens, billing, auth, database, and CI/CD security changes remain blocked
- Claude Code and Codex launches inside the command remain blocked
- GitHub mutation inside the command remains blocked
