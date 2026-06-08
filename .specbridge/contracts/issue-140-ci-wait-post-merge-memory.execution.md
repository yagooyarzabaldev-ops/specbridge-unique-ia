# Execution Contract: Issue 140 ci_wait and post_merge_memory Expansion

## Contract Metadata

- contract_id: issue-140-ci-wait-post-merge-memory
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/140
- created_by: Claude Code / SpecBridge executor
- created_at: 2026-06-07
- autonomy_profile: full_autopilot
- risk_level: medium
- status: ready_for_execution

## Goal

Expand the `issue-to-merge-github` apply-mode pilot scope guard to include `ci_wait` and `post_merge_memory`, completing the full autonomous loop. Fix apply-mode run artifact persistence.

## Context

The apply-mode pilot series proved `issue_close` (issue 119), `pr_open` (issue 123), `merge` (issue 126), and the combined three-operation call (issue 134). The remaining gaps in the fully autonomous loop are:

- `ci_wait`: the operator has no way to block until GitHub CI passes. Currently relies on `--auto` merge. Adding `ci_wait` makes CI polling explicit and observable.
- `post_merge_memory`: every merge generates a manual post-merge closure issue and governance package. Adding `post_merge_memory` automates this: the operator creates a closure branch, marks the scope completed, writes `closure.json`, and opens a PR with auto-merge.
- Run artifact write: apply-mode was not persisting the run artifact to disk on every run. Fixed to always write to the derived `$runPath`.

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
- `post_merge_memory` makes git commits and pushes to new branches and opens PRs autonomously.
- All changes are inside the declared scope. No secrets, production, billing, auth, database, CI/CD security, or deployment expansion.

## Allowed Scope

```text
scripts/specbridge.ps1
scripts/test-specbridge-cli.ps1
README.md
.specbridge/context/CURRENT_GOAL.md
.specbridge/contracts/issue-140-ci-wait-post-merge-memory.execution.md
.specbridge/scopes/issue-140-ci-wait-post-merge-memory.scope.json
.specbridge/scopes/issue-138-post-merge-closure-issue134.scope.json
.specbridge/reports/issue-140-ci-wait-post-merge-memory.final-report.json
.specbridge/audit-packets/issue-140-ci-wait-post-merge-memory.audit-packet.json
.specbridge/audits/issue-140-ci-wait-post-merge-memory.chatgpt-audit.json
GitHub pull request for this branch
GitHub issue 140 lifecycle comments/status updates
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

- `ci_wait` polls `gh pr checks` until required checks pass, fail, or time out. Reports status in the run artifact.
- `post_merge_memory` creates a closure branch from main, marks the scope as completed, writes `closure.json`, commits, pushes, opens a PR, and enables auto-merge.
- Apply-mode always writes the run artifact to the derived `$runPath`.
- Pilot scope guard updated: `ci_wait` and `post_merge_memory` are now supported. `issue_create` remains unsupported.
- `command_boundary` field updated to reflect the expanded set.
- Test updated: `apply-unsupported-op` uses `issue_create` (not `ci_wait`).
- All local validators pass.
- All CLI tests pass.

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

This task is complete when `ci_wait` and `post_merge_memory` are implemented in apply-mode, tests pass, and all validators pass.
