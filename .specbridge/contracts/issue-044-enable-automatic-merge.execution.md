# Execution Contract: Issue 44

## Contract Metadata

- contract_id: issue-044-enable-automatic-merge
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/44
- created_by: ChatGPT/Codex
- created_at: 2026-05-20
- autonomy_profile: full_autopilot
- risk_level: high
- status: ready_for_execution

## Goal

Enable gate-controlled automatic merge for SpecBridge by changing the default autonomy profile to Full Autopilot and allowing autonomous merge only after required gates pass.

## Context

The user requested that the merge configuration become automatic. This task changes SpecBridge governance policy and documentation so automatic merge is explicitly allowed when required validation, policy, review, and CI gates pass. Production deployment, secrets, billing, hosted runtime, and protected-branch weakening remain blocked.

## Source References

- README.md
- SPECBRIDGE.md
- AGENTS.md
- CLAUDE.md
- .specbridge/policy.yaml
- .specbridge/autonomy.yaml
- docs/specbridge-v4-product-contract.md
- docs/specbridge-mvp-operating-runbook.md

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
high
```

Reason:

- changes merge governance
- does not modify CI/CD security controls
- does not weaken required gates
- does not touch secrets, billing, production, or deployment

## Allowed Scope

```text
.specbridge/policy.yaml
.specbridge/autonomy.yaml
README.md
docs/specbridge-v4-product-contract.md
docs/specbridge-mvp-operating-runbook.md
docs/specbridge-phase-completion.md
docs/specbridge-v3-essential-product-scope.md
specs/001-product-requirements.md
specs/003-mvp-plan.md
specs/004-acceptance-tests.md
.specbridge/context/CURRENT_GOAL.md
.specbridge/context/ACCEPTANCE_CRITERIA.md
.specbridge/contracts/issue-044-enable-automatic-merge.execution.md
.specbridge/reports/issue-044-enable-automatic-merge.final-report.json
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
CI/CD security weakening
branch protection weakening
runtime product code
hosted dashboard implementation
MCP server implementation
GitHub App implementation
database schema implementation
autonomous deployment
```

## Acceptance Criteria

- `.specbridge/policy.yaml` sets `project.default_mode` to `full_autopilot`.
- `.specbridge/policy.yaml` sets `merge.autonomous_merge_enabled` to `true`.
- `.specbridge/autonomy.yaml` sets `default_profile` to `full_autopilot`.
- Documentation states automatic merge requires all configured gates to pass.
- Production deployment remains disabled.
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
powershell -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
git diff --check
```

## Stop Conditions

Execution must stop if the task requires secrets, production deployment, billing changes, authentication implementation, authorization implementation, CI/CD security weakening, branch protection weakening, runtime product code, hosted dashboard implementation, MCP server implementation, GitHub App implementation, database schema implementation, or autonomous deployment.

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

This task is complete only when the policy is updated, documentation reflects gate-controlled automatic merge, validations pass locally, the final report validates, and the branch is pushed to GitHub.

