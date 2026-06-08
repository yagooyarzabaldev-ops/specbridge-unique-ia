# Execution Contract: issue-153-lifecycle-guard

## Contract Metadata

- contract_id: issue-153-lifecycle-guard
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/153
- created_by: Claude Code / SpecBridge executor
- created_at: 2026-06-08
- autonomy_profile: full_autopilot
- risk_level: medium
- status: ready_for_execution

## Goal

Fix apply-mode lifecycle ordering violations proven by PR #150 open + issue #149 closed simultaneously. Implement lifecycle-guard CLI command and promote lifecycle violations to doctor blockers.

## Context

The previous session (issue-149 batch) revealed three ordering bugs:
1. `issue_close` executes before `pr_open` and `merge` in the operator code path
2. `merge` returns `success` when `gh pr merge --auto` is called, not when the PR is actually MERGED
3. `post_merge_memory` can run even when the primary PR is still OPEN

These produced live evidence: PR #150 open, issue #149 closed, closure PR #151 premature.

## Source References

- `scripts/specbridge.ps1` — apply-mode operator, issue_close block (line ~1445), merge block (line ~1560), post_merge_memory block (line ~1604)
- `scripts/test-specbridge-cli.ps1` — CLI test suite
- `.specbridge/policy.yaml` — policy declarations

## Autonomy Profile

Full Autopilot. No step-by-step permission required for normal implementation.

## Risk Level

Medium — changes apply-mode execution behavior; does not touch secrets, production, or auth.

## Allowed Scope

- `scripts/specbridge.ps1`
- `scripts/test-specbridge-cli.ps1`
- `.specbridge/policy.yaml`
- `.specbridge/contracts/issue-153-lifecycle-guard.execution.md`
- `.specbridge/scopes/issue-153-lifecycle-guard.scope.json`
- `.specbridge/scopes/issue-149-specbridge-operator-hardening.scope.json`
- `.specbridge/reports/issue-153-lifecycle-guard.final-report.json`
- `.specbridge/audit-packets/issue-153-lifecycle-guard.audit-packet.json`
- `.specbridge/audits/issue-153-lifecycle-guard.chatgpt-audit.json`
- `.specbridge/github-evidence/issue-153-lifecycle-guard.github-mutation-evidence.json`
- `README.md`
- `.specbridge/context/CURRENT_GOAL.md`

## Blocked Scope

- `.env`, `.env.*`, `secrets/**`, `infra/prod/**`
- `.github/workflows/**` (except `specbridge-intake.yml` which has an explicit path_override)
- Any file not listed in Allowed Scope

## Acceptance Criteria

1. `post_merge_memory` returns `blocked_pr_not_merged` if primary PR state is not `MERGED`
2. `issue_close` returns `blocked_merge_not_completed` if merge has not been confirmed
3. `merge` returns `auto_merge_enabled` when `gh pr merge --auto` succeeds but PR is still OPEN
4. `merge` returns `merge_completed` only when `gh pr view --json state` returns `state == "MERGED"`
5. `lifecycle-guard` CLI command detects and returns violations for: issue_closed+PR_open, premature_closure_PR, blocked_path_changed_without_override
6. `specbridge-doctor` returns `health: blocked` when lifecycle violations exist
7. Dashboard HTML includes "OPEN LIFECYCLE DEBT" section as the first visible section
8. `policy.yaml` declares `path_overrides` for `specbridge-intake.yml` and `lifecycle_guard` merge state rules
9. Tests cover: specbridge-doctor health/blockers fields, generate-dashboard OPEN LIFECYCLE DEBT section, lifecycle-guard violations/guard fields

## Required Validations

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/validate-foundation.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-contract-scopes.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/test-specbridge-cli.ps1
```

## Stop Conditions

- Secrets or credentials required
- Destructive database or production changes
- Impossible acceptance criteria

## Merge Policy

Autonomous merge allowed when all CI gates pass and all acceptance criteria are met.

## Deployment Policy

No deployment required.

## Final Report Requirements

JSON final report at `.specbridge/reports/issue-153-lifecycle-guard.final-report.json`.

## Completion Rule

Task is complete when all acceptance criteria are met and all required validations pass.
