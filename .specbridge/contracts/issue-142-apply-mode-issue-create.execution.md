# Execution Contract: Issue 142 Apply-Mode issue_create Operation

## Contract Metadata

- contract_id: issue-142-apply-mode-issue-create
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/142
- created_by: Claude Code / SpecBridge executor
- created_at: 2026-06-07
- autonomy_profile: full_autopilot
- risk_level: medium
- status: ready_for_execution

## Goal

Implement `issue_create` as the 6th apply-mode operation, completing the full autonomous 6-operation loop: `issue_create → pr_open → ci_wait → merge → issue_close → post_merge_memory`. Use SpecBridge to govern itself by running the full loop on issue 142.

## Context

The apply-mode pilot series proved `issue_close` (issue 119), `pr_open` (issue 123), `merge` (issue 126), the combined three-operation call (issue 134), and `ci_wait` + `post_merge_memory` (issue 140). The remaining gap is `issue_create`, which is the first operation in the default loop. Adding `issue_create` with create-or-verify semantics completes the loop: if a matching issue exists it returns `verified_existing`; if not it calls `gh issue create`.

Issue 142 is the first real use of the completed loop: SpecBridge governs itself using all 6 operations in a single apply-mode call.

## Source References

- scripts/specbridge.ps1
- scripts/test-specbridge-cli.ps1
- README.md
- SPECBRIDGE.md

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
medium
```

Reason:

- Modifies the core apply-mode execution block in specbridge.ps1.
- `issue_create` calls `gh issue create` if no matching issue exists — creates a new GitHub issue.
- create-or-verify semantics prevent duplicate issues.
- All changes are inside the declared scope. No secrets, production, billing, auth, database, CI/CD security, or deployment expansion.

## Allowed Scope

```text
scripts/specbridge.ps1
scripts/test-specbridge-cli.ps1
README.md
.specbridge/context/CURRENT_GOAL.md
.specbridge/contracts/issue-142-apply-mode-issue-create.execution.md
.specbridge/scopes/issue-142-apply-mode-issue-create.scope.json
.specbridge/scopes/issue-140-ci-wait-post-merge-memory.scope.json
.specbridge/reports/issue-142-apply-mode-issue-create.final-report.json
.specbridge/audit-packets/issue-142-apply-mode-issue-create.audit-packet.json
.specbridge/audits/issue-142-apply-mode-issue-create.chatgpt-audit.json
.specbridge/github-evidence/issue-142-apply-mode-issue-create.github-mutation-evidence.json
GitHub pull request for this branch
GitHub issue 142 lifecycle comments/status updates
```

## Blocked Scope

```text
.github/workflows/**
.env
.env.*
secrets/**
infra/prod/**
database changes
authentication implementation
authorization implementation
billing implementation
CI/CD security changes
deployment automation
production deployment
broad refactor outside apply-mode execution block
```

## Acceptance Criteria

- `issue_create` operation is implemented with create-or-verify semantics: search for existing issue by title; if found return `verified_existing`; if not call `gh issue create`.
- `issue_create` is added to the pilot scope guard alongside the other 5 operations.
- `command_boundary` updated to reflect all 6 operations.
- Test updated: `apply-unsupported-op` uses `issue_create` with blocked gates (verifies boundary string); since all 6 are supported, the test confirms `command_boundary` records pilot scope.
- Apply-mode run artifact always written to `$runPath` on disk.
- All local validators pass.
- All CLI tests pass.
- Full 6-operation apply-mode loop executes on issue 142: `issue_create → pr_open → ci_wait → merge → issue_close → post_merge_memory`.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contract-scopes.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-audit-packets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-chatgpt-audits.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-security-gates.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-review-gate.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/test-specbridge-cli.ps1
git diff --check
```

## Stop Conditions

Stop if the task requires secrets, production configuration, billing, authentication security, authorization security, dependency installation, database changes, CI/CD security changes, deployment automation, or production deployment.

## Merge Policy

Autonomous merge is allowed only after required local validations, GitHub CI, security gate, review gate, ChatGPT/Codex audit, no protected file changes, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

The final report must include summary, changed files, validations, policy result, risk result, merge status, deployment status, unresolved risks, and completion status.

## Completion Rule

This task is complete when `issue_create` is implemented in apply-mode, all validators pass, and the full 6-operation loop executes on issue 142.
