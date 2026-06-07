# Execution Contract: Issue 125 Post-Merge Closure for Issue 123

## Contract Metadata

- contract_id: issue-125-post-merge-closure-issue123
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/125
- created_by: Claude Code / SpecBridge coordinator
- created_at: 2026-06-07
- autonomy_profile: full_autopilot
- risk_level: medium
- status: ready_for_execution

## Goal

Close repository memory after PR 124 merged issue 123 (apply-mode pr_open expansion), demonstrate live apply-mode pr_open execution, and advance to issue 127 (apply-mode merge expansion).

This task must:

- update issue-123 evidence file with github_ci_passed true
- execute apply-mode pr_open to create the PR for this branch (live demonstration of gh pr create)
- create all issue 125 closure artifacts
- mark issue-123 scope as completed
- update CURRENT_GOAL.md to reflect issue 127 as next task
- update README.md with issue 123 complete and issue 125 status

## Context

Issue 123 added `pr_open` operation support to apply mode. PR 124 merged on 2026-06-07 after CI passed. Issue 123 was closed by auto-merge.

This closure task demonstrates apply-mode pr_open in live execution by using it to create the PR for this very branch (issue 125 closure), proving the mechanism works end-to-end.

## Source References

- README.md
- SPECBRIDGE.md
- AGENTS.md
- CLAUDE.md
- .specbridge/policy.yaml
- .specbridge/context/CURRENT_GOAL.md
- .specbridge/contracts/issue-123-apply-mode-pr-open.execution.md
- .specbridge/github-evidence/issue-123-apply-mode-pr-open.github-mutation-evidence.json
- scripts/specbridge.ps1
- https://github.com/yagooyarzabaldev-ops/specbridge/issues/123
- https://github.com/yagooyarzabaldev-ops/specbridge/issues/125
- https://github.com/yagooyarzabaldev-ops/specbridge/pull/124

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
medium
```

Reason:

- apply-mode pr_open calls gh pr create (real GitHub mutation)
- bounded by 7 evidence gates and explicit confirmation flags
- closure artifacts are memory/evidence only (low risk)

## Allowed Scope

```text
README.md
.specbridge/context/CURRENT_GOAL.md
.specbridge/contracts/issue-125-post-merge-closure-issue123.execution.md
.specbridge/scopes/issue-125-post-merge-closure-issue123.scope.json
.specbridge/scopes/issue-123-apply-mode-pr-open.scope.json
.specbridge/reports/issue-125-post-merge-closure-issue123.final-report.json
.specbridge/audit-packets/issue-125-post-merge-closure-issue123.audit-packet.json
.specbridge/audits/issue-125-post-merge-closure-issue123.chatgpt-audit.json
.specbridge/github-evidence/issue-123-apply-mode-pr-open.github-mutation-evidence.json
.specbridge/github-evidence/issue-125-post-merge-closure-issue123.closure.json
.specbridge/github-evidence/issue-125-post-merge-closure-issue123.github-mutation-evidence.json
GitHub issue 125
GitHub pull request for this branch (created via apply-mode pr_open)
```

## Blocked Scope

```text
.github/workflows/**
.env
.env.*
secrets/**
infra/prod/**
dependency installation
database changes
authentication implementation
authorization implementation
billing implementation
CI/CD security changes
deployment automation
production deployment
```

## Acceptance Criteria

- issue-123 evidence has github_ci_passed true.
- apply-mode pr_open executed successfully, creating PR for issue 125 branch.
- All issue 125 artifacts present.
- Issue-123 scope status updated to completed.
- CURRENT_GOAL.md describes issue 127 as current goal.
- README.md shows issue 123 complete and issue 125 in progress.
- CI passes on PR 125.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contract-scopes.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-audit-packets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-chatgpt-audits.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-security-gates.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-review-gate.ps1
git diff --check
```

## Stop Conditions

Stop if the task requires changes outside declared scope, protected credential access, production configuration, billing, authentication security, authorization security, dependency installation, database changes, CI/CD security changes, deployment automation.

## Merge Policy

Autonomous merge is allowed only after required local validations, GitHub CI, security gate, review gate, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

The final report must include summary, changed files, validations, policy result, risk result, merge status, deployment status, unresolved risks, and completion status.

## Completion Rule

This closure is complete when issue-123 post-merge evidence is updated, apply-mode pr_open demonstrates live gh pr create, CURRENT_GOAL points to issue 127, README reflects completed pr_open expansion, local validators pass, GitHub CI passes, and the branch is policy-gated into main.
