# Execution Contract: Issue 48

## Contract Metadata

- contract_id: issue-048-contract-scope-validator
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/48
- created_by: ChatGPT/Codex
- created_at: 2026-05-20
- autonomy_profile: full_autopilot
- risk_level: low
- status: ready_for_execution

## Goal

Add deterministic contract scope validation so SpecBridge can prevent overlapping multi-agent work before Claude Code execution starts.

## Context

The autonomy backlog identifies the Contract Scope Validator as the next task because safe Antigravity multi-agent execution requires explicit write ownership, read-only boundaries, coordinator-owned shared paths, dependency order, and unique final report paths.

## Source References

- README.md
- SPECBRIDGE.md
- .specbridge/policy.yaml
- .specbridge/context/CURRENT_GOAL.md
- .specbridge/context/ACCEPTANCE_CRITERIA.md
- docs/specbridge-autonomy-backlog.md
- docs/specbridge-multi-agent-antigravity-architecture.md

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
low
```

Reason:

- validation script and governance artifacts only
- no runtime product implementation code
- no secrets
- no production configuration
- no billing
- no authentication or authorization changes
- no CI/CD security weakening

## Allowed Scope

```text
scripts/validate-contract-scopes.ps1
scripts/test-specbridge-negative-validations.ps1
scripts/specbridge-smoke.ps1
docs/specbridge-contract-scope-validator.md
docs/specbridge-test-matrix.md
docs/specbridge-test-results.md
docs/specbridge-autonomy-backlog.md
specs/004-acceptance-tests.md
.specbridge/context/CURRENT_GOAL.md
.specbridge/context/ACCEPTANCE_CRITERIA.md
.specbridge/scopes/issue-048-contract-scope-validator.scope.json
.specbridge/contracts/issue-048-contract-scope-validator.execution.md
.specbridge/reports/issue-048-contract-scope-validator.final-report.json
```

## Blocked Scope

```text
.env
.env.*
secrets/**
infra/prod/**
runtime product code
package installation
hosted dashboard implementation
MCP server implementation
GitHub App implementation
database schema implementation
authentication implementation
authorization implementation
billing implementation
deployment automation
CI/CD security weakening
branch protection weakening
```

## Acceptance Criteria

- `scripts/validate-contract-scopes.ps1` exists.
- Scope manifests are validated from `.specbridge/scopes/*.scope.json`.
- Each scope manifest must declare `exclusive_write`, `read_only`, `coordinator_owned`, `dependencies`, and `final_report`.
- Active write ownership conflicts fail validation.
- Duplicate final report paths fail validation.
- Read/write relationships across active contracts require explicit dependencies.
- Disjoint active contracts pass validation.
- Negative validation tests cover missing scope fields, conflicting write paths, and duplicate final report paths.
- Smoke validation runs the contract scope validator.
- Documentation defines the scope manifest format and multi-agent usage.
- Required validations pass locally.

## Required Validations

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/validate-foundation.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-contract-scopes.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-schemas.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-pr-review-reports.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-claude-review-workflow.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-autonomous-execution-protocol.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-review-gate.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/test-specbridge-negative-validations.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
git diff --check
```

## Stop Conditions

Execution must stop if the task requires runtime product code, secrets, production deployment, billing changes, authentication implementation, authorization implementation, branch protection weakening, CI/CD security weakening, hosted dashboard implementation, MCP server implementation, GitHub App implementation, database schema implementation, or autonomous deployment.

## Merge Policy

Gate-controlled automatic merge is allowed only after required gates pass.

Autonomous merge must not bypass CI, validation, policy checks, review gates, or scope validation.

## Deployment Policy

No deployment is allowed.

```text
staging: disabled
production: disabled
```

## Final Report Requirements

The final report must include summary, changed files, validations, policy result, risk result, unresolved risks, merge status, deployment status, and completion status.

## Completion Rule

This task is complete only when the contract scope validator exists, required positive and negative fixtures pass, smoke validation includes the new validator, local validation evidence is recorded, the final report validates, and the branch is pushed to GitHub.
