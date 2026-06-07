# Execution Contract: Issue 121 Post-Merge Memory Closure for Issue 119

## Contract Metadata

- contract_id: issue-121-post-merge-closure-issue119
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/121
- created_by: Claude Code / SpecBridge coordinator
- created_at: 2026-06-06
- autonomy_profile: full_autopilot
- risk_level: low
- status: ready_for_execution

## Goal

Close repository memory after PR 120 merged issue 119 (apply-mode GitHub operator pilot), confirm issue 119 closed via apply-mode, and fix the ErrorActionPreference Stop bug discovered during apply-mode execution.

This task must:

- update the issue 119 evidence file with github_ci_passed true
- execute apply-mode issue_close on issue 119 to confirm goal state achieved
- fix the ErrorActionPreference Stop bug in specbridge.ps1 that caused NativeCommandError on gh stderr
- create all issue 121 closure artifacts (contract, scope, final report, audit packet, ChatGPT audit, closure artifact)
- mark issue 119 scope as completed
- update CURRENT_GOAL.md to reflect issue 123 as next task
- update README.md with issue 119 complete and issue 121 status

## Context

Issue 119 added the first real GitHub mutation in apply mode: `gh issue close` execution. PR 120 merged on 2026-06-06 after CI passed. Issue 119 was closed automatically by auto-merge. The evidence file still showed github_ci_passed false (pre-merge state).

A bug was found during apply-mode execution: `$ErrorActionPreference = "Stop"` caused a NativeCommandError exception when gh wrote to stderr (e.g. "already closed" message), preventing the script from outputting JSON. Fixed by wrapping the gh call with a temporary `$ErrorActionPreference = "Continue"` scope and treating "already closed" output as success.

## Source References

- README.md
- SPECBRIDGE.md
- AGENTS.md
- CLAUDE.md
- .specbridge/policy.yaml
- .specbridge/context/CURRENT_GOAL.md
- .specbridge/contracts/issue-119-apply-mode-github-operator-pilot.execution.md
- .specbridge/reports/issue-119-apply-mode-github-operator-pilot.final-report.json
- .specbridge/github-evidence/issue-119-apply-mode-github-operator-pilot.github-mutation-evidence.json
- scripts/specbridge.ps1
- https://github.com/yagooyarzabaldev-ops/specbridge/issues/119
- https://github.com/yagooyarzabaldev-ops/specbridge/issues/121
- https://github.com/yagooyarzabaldev-ops/specbridge/pull/120

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
low
```

Reason:

- the specbridge.ps1 fix is minimal: one ErrorActionPreference guard around a single gh call
- no product logic changed, only error handling for an already-closed issue case
- all other changes are evidence and memory files

## Allowed Scope

```text
README.md
.specbridge/context/CURRENT_GOAL.md
.specbridge/contracts/issue-121-post-merge-closure-issue119.execution.md
.specbridge/scopes/issue-121-post-merge-closure-issue119.scope.json
.specbridge/scopes/issue-119-apply-mode-github-operator-pilot.scope.json
.specbridge/reports/issue-121-post-merge-closure-issue119.final-report.json
.specbridge/audit-packets/issue-121-post-merge-closure-issue119.audit-packet.json
.specbridge/audits/issue-121-post-merge-closure-issue119.chatgpt-audit.json
.specbridge/github-evidence/issue-119-apply-mode-github-operator-pilot.github-mutation-evidence.json
.specbridge/github-evidence/issue-121-post-merge-closure-issue119.closure.json
scripts/specbridge.ps1
GitHub issue 121
GitHub pull request for this branch
```

## Blocked Scope

```text
product code
scripts/test-specbridge-cli.ps1
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

- `.specbridge/github-evidence/issue-119-apply-mode-github-operator-pilot.github-mutation-evidence.json` has github_ci_passed true.
- apply-mode issue_close result shows success (goal state confirmed, already-closed treated as success).
- `scripts/specbridge.ps1` gh call wrapped with ErrorActionPreference Continue.
- All issue 121 artifacts present and validators pass.
- Issue 119 scope status updated to completed.
- `CURRENT_GOAL.md` describes issue 123 as current goal.
- `README.md` shows issue 119 complete and issue 121 in progress.
- CI passes on PR 121.

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

This closure is complete when issue 119 post-merge evidence is updated, apply-mode confirms issue 119 closed, the ErrorActionPreference bug is fixed, CURRENT_GOAL points to issue 123, README reflects the completed apply-mode pilot, local evidence validators pass, GitHub CI passes, and the closure branch is policy-gated into main.
