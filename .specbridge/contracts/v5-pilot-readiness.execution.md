# Execution Contract: V5 Pilot Readiness

## Contract Metadata

- contract_id: v5-pilot-readiness
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/73
- created_by: ChatGPT/Codex
- created_at: 2026-06-03
- autonomy_profile: full_autopilot
- risk_level: medium
- status: completed

## Goal

Finish the next SpecBridge readiness layer for serious testing by adding a deterministic `v5-pilot-status` CLI command and a two-slice readiness evidence chain for the V5 live parallel Antigravity pilot.

## Context

Standard Loop v1 is merged and locally validated. The next product step is a live parallel V5 pilot, but live Antigravity execution must not start from informal memory. This task creates a local readiness gate that checks the V5 prerequisites, verifies at least two planned executor slices, records dry-run runtime evidence, and leaves the repository ready for a future live pilot contract.

This task does not launch Claude Code, Antigravity, GitHub automation, dependency installation, deployment, production changes, billing changes, authentication changes, authorization changes, database changes, or CI/CD security changes.

## Source References

- README.md
- SPECBRIDGE.md
- AGENTS.md
- CLAUDE.md
- .specbridge/policy.yaml
- .specbridge/context/CURRENT_GOAL.md
- docs/specbridge-standard-loop-v1.md
- docs/specbridge-v5-live-parallel-pilot-boundary.md
- docs/specbridge-autonomy-backlog.md
- scripts/specbridge.ps1
- scripts/test-specbridge-cli.ps1
- https://github.com/yagooyarzabaldev-ops/specbridge/issues/73

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
medium
```

Reason:

- this task changes the local SpecBridge CLI and its test coverage
- it adds repository evidence used by future live parallel execution
- it remains file-backed and dry-run only
- it does not change CI/CD workflows, secrets, production, billing, auth, database, dependencies, or deployment

## Allowed Scope

```text
.specbridge/audit-packets/v5-pilot-readiness.audit-packet.json
.specbridge/audits/v5-pilot-readiness.chatgpt-audit.json
.specbridge/context/CURRENT_GOAL.md
.specbridge/contracts/v5-pilot-readiness.execution.md
.specbridge/executor-handoffs/v5-pilot-readiness.input.json
.specbridge/executor-packets/v5-pilot-readiness-cli-readiness.executor-packet.json
.specbridge/executor-packets/v5-pilot-readiness-test-readiness.executor-packet.json
.specbridge/metrics/v5-pilot-readiness.autonomy-metrics.json
.specbridge/reports/v5-pilot-readiness.final-report.json
.specbridge/runtime-evidence/v5-pilot-readiness-cli-readiness.executor-output.md
.specbridge/runtime-evidence/v5-pilot-readiness-test-readiness.executor-output.md
.specbridge/runtime-executions/v5-pilot-readiness-cli-readiness.runtime-execution.json
.specbridge/runtime-executions/v5-pilot-readiness-test-readiness.runtime-execution.json
.specbridge/runtime-launches/v5-pilot-readiness-cli-readiness.runtime-launch.json
.specbridge/runtime-launches/v5-pilot-readiness-test-readiness.runtime-launch.json
.specbridge/runtime-results/v5-pilot-readiness-cli-readiness.runtime-result.json
.specbridge/runtime-results/v5-pilot-readiness-test-readiness.runtime-result.json
.specbridge/runtime-runs/v5-pilot-readiness-cli-readiness.runtime-run.json
.specbridge/runtime-runs/v5-pilot-readiness-test-readiness.runtime-run.json
.specbridge/runtime-summaries/v5-pilot-readiness-cli-readiness.runtime-summary.json
.specbridge/runtime-summaries/v5-pilot-readiness-test-readiness.runtime-summary.json
.specbridge/scopes/v5-pilot-readiness.scope.json
README.md
docs/specbridge-autonomy-backlog.md
docs/specbridge-standard-loop-v1.md
docs/specbridge-test-results.md
docs/specbridge-v5-live-parallel-pilot-boundary.md
scripts/specbridge.ps1
scripts/test-specbridge-cli.ps1
GitHub pull request for this branch
```

## Blocked Scope

```text
.env
.env.*
secrets/**
infra/prod/**
.github/workflows/**
package installation
dependency installation
hosted dashboard implementation
MCP server implementation
GitHub App implementation
database schema implementation
authentication implementation
authorization implementation
billing implementation
deployment automation
CI/CD permission escalation
CI/CD security weakening
branch protection weakening
raw protected credential capture
production deployment
destructive infrastructure operation
unrestricted shell execution
live Claude Code launch
live Antigravity session launch
```

## Acceptance Criteria

- `v5-pilot-status` exists in `scripts/specbridge.ps1`.
- `v5-pilot-status` reports V5 readiness from repository evidence.
- The command requires Standard Loop v1 paths, runtime evidence validators, controlled runner dry-run evidence, V5 boundary documentation, current V5 goal memory, a readiness contract, a readiness scope, a V5 executor handoff, at least two executor packets, at least two runtime launch plans, at least two runtime dry-run execution artifacts, at least two ready runtime summaries, and autonomy metrics.
- The command reports a live execution boundary that blocks secrets, production, billing, auth security, CI/CD security changes, and deployment.
- The CLI test suite covers `v5-pilot-status`.
- V5 readiness has a two-slice executor handoff with non-overlapping write scopes.
- Runtime evidence for the readiness slices is dry-run or evidence-capture only and does not claim live Claude/Antigravity execution.
- Local validations pass for contracts, scopes, schemas, executor packets, runtime launches, runtime executions, runtime runs, runtime results, runtime summaries, autonomy metrics, final reports, audit packets, ChatGPT audits, standard profile, CLI tests, security gate, review gate, smoke, and git diff whitespace.
- No secrets, production configuration, billing, auth security, dependency installation, database changes, CI/CD weakening, live execution, or deployment automation are involved.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 v5-pilot-status
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contract-scopes.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-executor-packets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-launches.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-executions.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-runs.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-results.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-summaries.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-autonomy-metrics.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-audit-packets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-chatgpt-audits.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 validate -Profile standard
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/test-specbridge-cli.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/test-specbridge-negative-validations.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-security-gates.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-review-gate.ps1
git diff --check
```

## Stop Conditions

Execution must stop if the task requires live Claude/Antigravity launch, workflow security changes, secrets, production configuration, billing, authentication or authorization security changes, dependency installation, database changes, deployment automation, protected file changes, or scope outside the declared paths.

## Merge Policy

Gate-controlled automatic merge is allowed only after required local validations, GitHub CI, deterministic review report, security gate, review gate, audit packet validation, ChatGPT/Codex audit validation, scope validation, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

The final report must include summary, changed files, validations, V5 readiness evidence, two-slice dry-run evidence, autonomy metrics evidence, policy result, risk result, merge status, deployment status, unresolved risks, and rollback notes if applicable.

## Completion Rule

This task is complete only when `v5-pilot-status` returns `ok: true`, the readiness evidence chain validates locally, the final report and ChatGPT/Codex audit are present, and no policy boundary has been crossed.
