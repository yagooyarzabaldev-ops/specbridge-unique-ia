# Execution Contract: Issue 59 Branch Per Executor Orchestration

## Contract Metadata

- contract_id: issue-059-branch-per-executor-orchestration
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/59
- created_by: ChatGPT/Codex
- created_at: 2026-05-20
- autonomy_profile: full_autopilot
- risk_level: medium
- status: ready_for_execution

## Goal

Add the next SpecBridge autonomy layer after executor handoff: deterministic branch-per-executor planning plus coordinator evidence aggregation for simulated and real GitHub executor runs.

## Context

The live Antigravity executor handoff milestone created one handoff packet per executor. The next product proof must map those packets to independent executor branches and PR evidence while preserving the rule that only real GitHub evidence can authorize merge. Simulation is allowed only to test the coordinator flow.

## Source References

- README.md
- SPECBRIDGE.md
- AGENTS.md
- .specbridge/policy.yaml
- docs/specbridge-live-antigravity-executor-handoff.md
- docs/specbridge-multi-agent-antigravity-architecture.md
- docs/specbridge-autonomy-backlog.md
- .specbridge/context/CURRENT_GOAL.md
- .specbridge/context/ACCEPTANCE_CRITERIA.md

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
medium
```

Reason:

- the task extends local orchestration behavior and validation
- the implementation writes deterministic repository artifacts
- live Antigravity launch, live Claude Code process launch, child PR creation, protected resource access, production deployment, dependency installation, hosted dashboard implementation, MCP runtime, and GitHub App runtime remain blocked

## Allowed Scope

```text
scripts/specbridge.ps1
scripts/validate-branch-orchestrations.ps1
scripts/test-specbridge-branch-orchestration.ps1
scripts/test-specbridge-cli.ps1
scripts/specbridge-smoke.ps1
README.md
.specbridge/branch-plans/issue-059-branch-per-executor-orchestration.branch-plan.json
.specbridge/orchestrations/issue-059-branch-per-executor-orchestration.executor-orchestration.json
.specbridge/contracts/issue-059-branch-per-executor-orchestration.execution.md
.specbridge/scopes/issue-059-branch-per-executor-orchestration.scope.json
.specbridge/reports/issue-059-branch-per-executor-orchestration.final-report.json
.specbridge/audit-packets/issue-059-branch-per-executor-orchestration.audit-packet.json
.specbridge/audits/issue-059-branch-per-executor-orchestration.chatgpt-audit.json
.specbridge/context/CURRENT_GOAL.md
.specbridge/context/ACCEPTANCE_CRITERIA.md
docs/specbridge-branch-per-executor-orchestration.md
docs/specbridge-local-cli.md
docs/specbridge-autonomy-backlog.md
docs/specbridge-test-matrix.md
docs/specbridge-test-results.md
specs/004-acceptance-tests.md
```

## Blocked Scope

```text
.env
.env.*
secrets/**
infra/prod/**
src/**
app/**
apps/**
packages/**
lib/**
server/**
client/**
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
raw file content capture
network calls by default
live Antigravity session launch
live Claude Code process launch
child PR creation
live executor branch creation
merge based on simulated evidence
```

## Acceptance Criteria

- `scripts/specbridge.ps1` supports `plan-executor-branches`.
- `plan-executor-branches` reads executor packets and writes `.specbridge/branch-plans/*.branch-plan.json`.
- Each branch plan declares one branch per executor packet.
- Each executor branch entry declares branch name, base branch, PR status, CI status, ChatGPT audit status, validation commands, and rollback notes.
- `scripts/specbridge.ps1` supports `coordinate-executors`.
- `coordinate-executors` writes `.specbridge/orchestrations/*.executor-orchestration.json`.
- Simulation mode marks PR, CI, and audit values as simulated and prevents merge authorization.
- GitHub evidence mode requires real GitHub PR URLs, passed CI, and approved ChatGPT audit status before integration can be marked ready.
- `scripts/validate-branch-orchestrations.ps1` validates branch plan and orchestration artifacts.
- `scripts/test-specbridge-branch-orchestration.ps1` covers branch planning, simulated coordination, validation, duplicate branch rejection, and simulation merge blocking.
- `scripts/test-specbridge-cli.ps1` covers the new CLI commands.
- `scripts/specbridge-smoke.ps1` runs branch orchestration validation and tests.
- Documentation, acceptance criteria, test matrix, test results, final report, audit packet, and ChatGPT audit are updated.

## Required Validations

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 plan-executor-branches -TaskId issue-059-branch-per-executor-orchestration -InputPath .specbridge/executor-packets -OutputPath .specbridge/branch-plans/issue-059-branch-per-executor-orchestration.branch-plan.json -Force
powershell -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 coordinate-executors -InputPath .specbridge/branch-plans/issue-059-branch-per-executor-orchestration.branch-plan.json -OutputPath .specbridge/orchestrations/issue-059-branch-per-executor-orchestration.executor-orchestration.json -EvidenceMode simulation -Force
powershell -ExecutionPolicy Bypass -File ./scripts/validate-branch-orchestrations.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/test-specbridge-branch-orchestration.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/test-specbridge-cli.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-foundation.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-contract-scopes.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-schemas.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-audit-packets.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-chatgpt-audits.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-executor-packets.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-security-gates.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-pr-review-reports.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-claude-review-workflow.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-autonomous-execution-protocol.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-review-gate.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/test-specbridge-negative-validations.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
git diff --check
```

## Stop Conditions

Execution must stop if the task requires protected credential access, production deployment, billing changes, authentication implementation, authorization implementation, branch protection weakening, CI/CD permission escalation, CI/CD security weakening, hosted dashboard implementation, MCP server implementation, GitHub App implementation, database schema implementation, dependency installation, live Antigravity session launch, live Claude Code process launch, child PR creation, live executor branch creation, default network calls, autonomous deployment, raw protected credential capture, or merge based on simulated evidence.

## Merge Policy

Gate-controlled automatic merge is allowed only after required gates pass.

Autonomous merge must not bypass CI, validation, policy checks, review gates, security gate validation, branch orchestration validation, branch orchestration tests, audit packet validation, ChatGPT audit validation, or scope validation.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

The final report must include summary, changed files, validations, policy result, risk result, unresolved risks, merge status, deployment status, rollback notes if applicable, and completion status.

## Completion Rule

This task is complete only when branch plan and coordinator artifacts exist and validate, simulation is explicitly non-mergeable, local validation evidence is recorded, final report and audit evidence validate, CI passes on GitHub, and the pull request is merged by policy gates.
