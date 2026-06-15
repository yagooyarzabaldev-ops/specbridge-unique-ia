# Execution Contract: Reconcile Historical Doctor Warnings

## Contract Metadata

- contract_id: reconcile-historical-doctor-warnings
- run_id: sb-20260615-0d0c70c1
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/172
- created_by: ChatGPT/Codex
- created_at: 2026-06-15
- autonomy_profile: full_autopilot
- risk_level: low
- status: completed

## Goal

Reconcile the remaining historical `specbridge-doctor -FixPlan -Offline` warnings for completed tasks whose GitHub PRs and issues are already closed, without rerunning obsolete apply-mode flows or changing product code.

## Context

`specbridge-doctor` reports historical warnings for completed scopes that predate complete closure evidence and ledger coverage:

- `issue-172-specbridge-trace-run-id`
- `issue-174-specbridge-studio-dashboard`
- `issue-177-repo-memory-cleanup-after-studio`
- `issue-178-specbridge-multi-agent-orchestration-manifest`

GitHub evidence confirms these tasks were completed through merged PRs and closed issues. The correct remediation is evidence reconciliation: add missing closure files for completed scopes that lack them, append truthful historical ledger reconciliation entries for the affected run IDs, update the current goal memory so it no longer references stale PR #200 debt, regenerate dashboards, and validate repository health.

## Source References

- `.specbridge/context/CURRENT_GOAL.md` - repository memory and next recommended task.
- `.specbridge/scopes/issue-172-specbridge-trace-run-id.scope.json` - completed scope with run ID `sb-20260608-abcd0172`.
- `.specbridge/scopes/issue-174-specbridge-studio-dashboard.scope.json` - completed scope with run ID `sb-20260609-cc04eda9`.
- `.specbridge/scopes/issue-177-repo-memory-cleanup-after-studio.scope.json` - completed scope with run ID `sb-20260609-b3bc65dc`.
- `.specbridge/scopes/issue-178-specbridge-multi-agent-orchestration-manifest.scope.json` - completed scope with run ID `sb-20260609-06e1b8e9`.
- `.specbridge/github-evidence/*.closure.json` - closure evidence checked by `specbridge-doctor`.
- `.specbridge/ledger/operations.ndjson` - append-only operation ledger checked by `specbridge-doctor`.
- `.specbridge/state/current-goal.json` - machine-readable current goal pointer for dashboards and operators.
- `docs/status-dashboard.html` and `docs/specbridge-studio.html` - generated health dashboards.

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

Low. The task changes governance evidence, ledger entries, repository memory, generated dashboards, and task audit artifacts only. It does not change runtime behavior, workflows, dependencies, secrets, production configuration, billing, authentication, authorization, database operations, deployment automation, or CI/CD security controls.

## Allowed Scope

```text
.specbridge/contracts/reconcile-historical-doctor-warnings.execution.md
.specbridge/scopes/reconcile-historical-doctor-warnings.scope.json
.specbridge/reports/reconcile-historical-doctor-warnings.final-report.json
.specbridge/audit-packets/reconcile-historical-doctor-warnings.audit-packet.json
.specbridge/audits/reconcile-historical-doctor-warnings.chatgpt-audit.json
.specbridge/github-evidence/reconcile-historical-doctor-warnings.closure.json
.specbridge/github-evidence/issue-172-specbridge-trace-run-id.closure.json
.specbridge/github-evidence/issue-177-repo-memory-cleanup-after-studio.closure.json
.specbridge/ledger/operations.ndjson
.specbridge/context/CURRENT_GOAL.md
.specbridge/state/current-goal.json
docs/status-dashboard.html
docs/specbridge-studio.html
```

## Blocked Scope

```text
.github/workflows/**
.env
.env.*
secrets/**
infra/prod/**
scripts/**
source code behavior changes
operator decision registry changes
issue #194 lifecycle changes
digital twin implementation
dependency installation
deployment automation
production deployment
authentication implementation
authorization implementation
billing implementation
database changes
CI/CD security changes
```

## Acceptance Criteria

1. Missing closure evidence exists for completed scopes `issue-172-specbridge-trace-run-id` and `issue-177-repo-memory-cleanup-after-studio`.
2. Ledger entries exist for run IDs `sb-20260608-abcd0172`, `sb-20260609-cc04eda9`, `sb-20260609-b3bc65dc`, and `sb-20260609-06e1b8e9` without claiming a historical apply-mode execution that did not happen.
3. `CURRENT_GOAL.md` no longer reports PR #200 as open or failing.
4. Dashboards are regenerated from the reconciled evidence.
5. `specbridge-doctor -FixPlan -Offline` reports healthy with zero actions, or any residual warning is recorded as an unresolved risk with evidence.
6. Full SpecBridge smoke remains green locally and in GitHub Actions.
7. After PR #204 merges, this scope is marked completed and closure evidence records the merge commit.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 -Command generate-dashboard
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 -Command generate-studio-dashboard
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 -Command specbridge-doctor -FixPlan -Offline -OutputFormat json
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contract-scopes.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-audit-packets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-chatgpt-audits.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
git diff --check
```

## Stop Conditions

Stop if the task requires secrets, production configuration, billing, authentication security, authorization security, database changes, dependency installation, deployment automation, CI/CD security changes, modifying workflow files, changing operator decisions, reviving issue #194, implementing the digital twin, or claiming unverifiable GitHub/CI evidence.

## Merge Policy

Autonomous merge is allowed only after required local validations, GitHub CI, security gate, review gate, no protected file changes, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

Write `.specbridge/reports/reconcile-historical-doctor-warnings.final-report.json`, `.specbridge/audit-packets/reconcile-historical-doctor-warnings.audit-packet.json`, and `.specbridge/audits/reconcile-historical-doctor-warnings.chatgpt-audit.json`. The report must state changed files, validations, policy result, risk result, merge status, deployment status, unresolved risks, and completion status.

## Completion Rule

Task is complete when the historical doctor warnings are reconciled through repository evidence, dashboards are regenerated, required validations pass locally, GitHub checks pass on the PR, and the PR is merged or explicitly left open with the remaining blocker recorded.
