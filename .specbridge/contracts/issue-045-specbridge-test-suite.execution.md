# Execution Contract: Issue 45

## Contract Metadata

- contract_id: issue-045-specbridge-test-suite
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/45
- created_by: ChatGPT/Codex
- created_at: 2026-05-20
- autonomy_profile: full_autopilot
- risk_level: medium
- status: ready_for_execution

## Goal

Add a deterministic SpecBridge test phase that validates both passing artifacts and expected failure behavior.

## Context

SpecBridge now has foundation, MVP, V3, V4, and gate-controlled automatic merge policy. The next required work is proving the validation layer with explicit test evidence, including negative cases that must fail for the expected reason.

## Source References

- README.md
- SPECBRIDGE.md
- docs/specbridge-mvp-operating-runbook.md
- docs/specbridge-v4-product-contract.md
- scripts/validate-foundation.ps1
- scripts/validate-contracts.ps1
- scripts/validate-final-reports.ps1
- scripts/validate-review-gate.ps1
- scripts/specbridge-smoke.ps1
- .specbridge/policy.yaml
- .specbridge/autonomy.yaml

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
medium
```

Reason:

- adds validation test script
- updates smoke validation
- no production configuration
- no secrets
- no billing
- no runtime product implementation
- no CI/CD security weakening

## Allowed Scope

```text
scripts/test-specbridge-negative-validations.ps1
scripts/specbridge-smoke.ps1
docs/specbridge-test-matrix.md
docs/specbridge-test-results.md
specs/004-acceptance-tests.md
.specbridge/context/ACCEPTANCE_CRITERIA.md
.specbridge/contracts/issue-045-specbridge-test-suite.execution.md
.specbridge/reports/issue-045-specbridge-test-suite.final-report.json
```

## Blocked Scope

```text
.env
.env.*
secrets/**
infra/prod/**
production deployment
billing configuration
authentication implementation
authorization implementation
branch protection weakening
CI/CD security weakening
runtime product code
hosted dashboard implementation
MCP server implementation
GitHub App implementation
database schema implementation
autonomous deployment
```

## Acceptance Criteria

- Test matrix document exists.
- Test results document exists.
- Negative validation runner exists.
- Negative validation runner verifies at least foundation, contract, final report, and PR review gate failure behavior.
- Smoke validation runs the negative validation runner.
- Acceptance criteria mention SpecBridge test suite evidence.
- Required validations pass locally.
- Final report exists and validates.
- Existing unrelated untracked local files are not staged.

## Required Validations

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/validate-foundation.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
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

Execution must stop if the task requires secrets, production deployment, billing changes, authentication implementation, authorization implementation, branch protection weakening, CI/CD security weakening, runtime product code, hosted dashboard implementation, MCP server implementation, GitHub App implementation, database schema implementation, or autonomous deployment.

## Merge Policy

Gate-controlled automatic merge is allowed only after required gates pass.

Autonomous merge must not bypass CI, validation, policy checks, or review gates.

## Deployment Policy

No deployment is allowed.

```text
staging: disabled
production: disabled
```

## Final Report Requirements

The final report must include summary, changed files, validations, policy result, risk result, unresolved risks, merge status, deployment status, and completion status.

## Completion Rule

This task is complete only when the test matrix, test result artifact, negative validation runner, smoke integration, execution contract, and final report exist; all required validations pass locally; and the branch is pushed to GitHub.

