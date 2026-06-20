# Execution Contract: Issue 228 Standard Readiness Status

## Contract Metadata

- contract_id: issue-228-standard-readiness-status
- run_id: sb-20260620-0228a1b2
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/228
- created_by: ChatGPT/Codex
- created_at: 2026-06-20
- autonomy_profile: full_autopilot
- risk_level: medium
- status: ready_for_execution

## Goal

Add a deterministic, read-only SpecBridge standard readiness status command that aggregates existing local operator evidence before a new governed task starts.

## Context

SpecBridge has separate local evidence surfaces for doctor health, next-task selection, repository health, token/context governance, and MCP resource exports. Operators can already inspect each surface individually, but there is no single command that answers whether the repository is ready to start, continue, or block a standard governed execution.

This task adds that aggregate readiness view without changing cleanup, retention, GitHub mutation, live runtime, MCP server runtime, deployment, CI/CD security, secrets, billing, authentication, authorization, or production behavior.

## Source References

- `README.md` - product status and current standardization posture.
- `SPECBRIDGE.md` - execution contract and policy hierarchy.
- `AGENTS.md` - repository operating rules.
- `.specbridge/policy.yaml` - active repository policy.
- `.specbridge/context/CURRENT_GOAL.md` - current stage and required next-task process.
- `scripts/lib/intake-doctor.ps1` - doctor and next-task source logic.
- `scripts/lib/repository-health-summary.ps1` - repository health aggregation.
- `scripts/lib/token-governance.ps1` - token/context governance status.
- `scripts/lib/mcp-resources.ps1` - read-only MCP resource catalog.
- `scripts/lib/artifact-inventory.ps1` - artifact family inventory.
- `scripts/specbridge.ps1` - CLI entry point.
- `scripts/test-specbridge-cli.ps1` - CLI regression suite.

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

Medium. The task changes CLI routing, tests, repository documentation, and governance/evidence artifacts. Runtime behavior is read-only unless a declared output artifact path is provided. The command must not mutate GitHub, launch Claude Code, launch Codex, call the network, read secrets, change billing, change CI/CD security, enforce cleanup, enforce retention, or deploy.

## Allowed Scope

```text
.specbridge/contracts/issue-228-standard-readiness-status.execution.md
.specbridge/scopes/issue-228-standard-readiness-status.scope.json
.specbridge/reports/issue-228-standard-readiness-status.final-report.json
.specbridge/audit-packets/issue-228-standard-readiness-status.audit-packet.json
.specbridge/audits/issue-228-standard-readiness-status.chatgpt-audit.json
.specbridge/ledger/operations.ndjson
.specbridge/state/current-goal.json
.specbridge/context/CURRENT_GOAL.md
.specbridge/standard-readiness/current.status.json
.specbridge/artifact-inventory/current.inventory.json
.specbridge/mcp-resources/operator-state.catalog.json
README.md
docs/specbridge-standard-readiness-status.md
docs/status-dashboard.html
docs/specbridge-studio.html
scripts/specbridge.ps1
scripts/lib/standard-readiness.ps1
scripts/lib/artifact-inventory.ps1
scripts/test-specbridge-cli.ps1
```

## Blocked Scope

```text
.github/workflows/**
.env
.env.*
secrets/**
infra/prod/**
.mcp.json
.mcp.*.json
dependency installation
package manager files
real MCP server runtime
Claude Code runtime launches
Codex runtime launches
GitHub mutations from the readiness command
branch deletion, pruning, renaming, movement, archive, fetch, pull, force-push, or cleanup apply mode
artifact deletion, movement, compression, pruning, archival implementation, upload, or retention enforcement
secret access
billing configuration
provider account configuration
authentication implementation
authorization implementation
database changes
CI/CD security changes
deployment automation
production deployment
operator decision changes
issue #194 lifecycle changes
digital twin implementation
```

## Acceptance Criteria

1. A deterministic `specbridge-standard-readiness` CLI command exists.
2. The command returns valid JSON and reports doctor health, next-task posture, repository health posture, token/context governance posture, MCP resource surface posture, and standard execution boundaries.
3. The command reports a readiness enum that can distinguish `ready_for_governed_task_intake`, `continue_current_goal`, `execute_eligible_task`, `review_recommended`, and `blocked`.
4. The command performs no network calls, Claude launches, Codex launches, GitHub mutations, dependency installation, secret access, billing changes, cleanup enforcement, retention enforcement, CI/CD security changes, or deployment.
5. The command is read-only when `-OutputPath` is omitted.
6. The command can optionally write `.specbridge/standard-readiness/current.status.json` through `-OutputPath` and requires `-Force` when replacing that artifact.
7. Artifact inventory includes the `standard_readiness` artifact family with cleanup permission disabled.
8. Documentation explains the readiness fields, command usage, boundaries, and how operators should use the command before starting new governed work.
9. CLI regression coverage validates command shape, deterministic read-only output, required fields, readiness enum, blocked boundaries, output-path behavior, force behavior, bad path behavior, and artifact inventory family coverage.
10. Required final report, audit packet, and ChatGPT/Codex audit evidence are written.
11. Required validation scripts and smoke pass locally and in GitHub Actions.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contract-scopes.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/test-specbridge-cli.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-audit-packets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-chatgpt-audits.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
git diff --check
```

## Stop Conditions

Stop if the task requires secrets, provider tokens, private keys, billing configuration, provider account configuration, authentication security changes, authorization security changes, database changes, dependency installation, deployment automation, production configuration, CI/CD security changes, workflow changes, branch cleanup enforcement, artifact retention enforcement, cleanup apply mode, GitHub mutation from the readiness command, changing operator decisions, reviving issue #194, or implementing the digital twin.

## Claude Code Delegation

Claude Code may inspect and implement files in allowed scope only. Claude must read this contract, the scope manifest, `README.md`, `SPECBRIDGE.md`, `AGENTS.md`, `.specbridge/policy.yaml`, and `.specbridge/context/CURRENT_GOAL.md` before changing files. Claude must not run blocked commands and must stop rather than implement cleanup, retention, GitHub mutation, live runtime, MCP server runtime, or deployment behavior.

## Merge Policy

Autonomous merge is allowed only after required local validations, GitHub CI, security gate, review gate, no protected file changes, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

Write `.specbridge/reports/issue-228-standard-readiness-status.final-report.json`, `.specbridge/audit-packets/issue-228-standard-readiness-status.audit-packet.json`, and `.specbridge/audits/issue-228-standard-readiness-status.chatgpt-audit.json`. The report must state changed files, validations, policy result, risk result, merge status, deployment status, unresolved risks, and completion status.

## Completion Rule

Task is complete when standard readiness status is implemented, all required local validations pass, GitHub checks pass, PR closes issue #228, and post-merge closure evidence is recorded.
