# Execution Contract: Test intake bridge end-to-end via gh workflow run

## Contract Metadata

- contract_id: issue-157-intake-bridge-end-to-end-test
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/157
- created_by: specbridge-intake
- created_at: 2026-06-08
- autonomy_profile: full_autopilot
- risk_level: medium
- status: ready_for_execution

## Goal

Validate the full specbridge-intake to apply-mode loop runs autonomously from a ChatGPT trigger via gh workflow run. The intake command should generate governance files (contract, scope, evidence) and push a ready-to-execute branch.

## Context

First live end-to-end test of the SpecBridge intake bridge. The specbridge-intake.yml GitHub Action was triggered via gh workflow run, generating governance files (contract, scope, evidence) and pushing branch codex/issue-157-intake-bridge-end-to-end-test. This task validates that the generated branch can be executed through the full apply-mode operator loop without manual intervention.

## Source References

- `.github/workflows/specbridge-intake.yml` — the intake workflow triggered externally
- `scripts/specbridge.ps1` — specbridge-intake command and issue-to-merge-github operator
- `.specbridge/github-evidence/issue-157-intake-bridge-end-to-end-test.github-mutation-evidence.json` — intake-generated evidence

## Risk Level

Medium — adds governance files and runs GitHub mutations; does not touch secrets, production, or authentication.

## Autonomy Profile

```text
full_autopilot
```

## Allowed Scope

```text
README.md
.specbridge/context/CURRENT_GOAL.md
.specbridge/contracts/issue-157-intake-bridge-end-to-end-test.execution.md
.specbridge/scopes/issue-157-intake-bridge-end-to-end-test.scope.json
.specbridge/reports/issue-157-intake-bridge-end-to-end-test.final-report.json
.specbridge/audit-packets/issue-157-intake-bridge-end-to-end-test.audit-packet.json
.specbridge/audits/issue-157-intake-bridge-end-to-end-test.chatgpt-audit.json
.specbridge/github-evidence/issue-157-intake-bridge-end-to-end-test.github-mutation-evidence.json
GitHub pull request for this branch
GitHub issue lifecycle comments/status updates
```

## Blocked Scope

```text
.github/workflows/**
.env
secrets/**
infra/prod/**
database changes
authentication implementation
billing implementation
deployment automation
production deployment
```

## Acceptance Criteria

1. `specbridge-intake.yml` workflow triggers successfully via `gh workflow run` and outputs `status: ready`
2. The generated branch includes contract, scope, and evidence files with all required fields
3. The apply-mode operator runs all 6 operations from the intake branch without manual intervention
4. GitHub issue is created, PR is opened, CI passes, PR merges, issue closes, post_merge_memory runs
5. `validate-foundation` CI passes on the intake branch PR

## Required Validations

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/validate-foundation.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/test-specbridge-cli.ps1
```

## Stop Conditions

Stop if the task requires secrets, production configuration, billing, authentication security, database changes, or deployment automation.

## Merge Policy

Autonomous merge is allowed only after required local validations, GitHub CI, security gate, review gate, ChatGPT/Codex audit, no protected file changes, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

JSON final report at `.specbridge/reports/issue-157-intake-bridge-end-to-end-test.final-report.json`.

## Completion Rule

Task is complete when the intake branch PR merges and all 6 apply-mode operations execute successfully.