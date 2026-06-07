# Execution Contract: Issue 117 Post-Merge Memory Closure

## Contract Metadata

- contract_id: issue-117-post-merge-memory-closure
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/117
- created_by: Claude Code / SpecBridge coordinator
- created_at: 2026-06-06
- autonomy_profile: full_autopilot
- risk_level: low
- status: ready_for_execution

## Goal

Close repository memory after PR 116 merged issue 115 (GitHub evidence loop pilot) and set the next recommended task as issue 119 (apply-mode GitHub operator pilot for a single low-risk operation).

This task must:

- update `CURRENT_GOAL.md` so it no longer says issue 115 is the active phase
- update README.md to mark the issue-to-merge GitHub evidence loop as complete and record the next phase
- update the issue 115 final report to reflect that PR 116 merged and GitHub CI passed
- create issue 117 closure evidence
- avoid product code changes, script changes, or workflow changes

## Context

Issue 115 added the first governed GitHub evidence loop: a dry-run `issue-to-merge-github` connector action envelope compared with real GitHub lifecycle evidence for issue 115. PR 116 merged on 2026-06-06. Issue 115 is now closed on GitHub.

Repository memory (`CURRENT_GOAL.md`) still describes issue 115 as the active phase with unresolved PR/CI/merge/closure gates. Those gates are now resolved. This closure corrects that state and records the next ordered task.

The next recommended task is issue 119: pilot `issue-to-merge-github` in apply-mode for exactly one low-risk GitHub operation (closing the completed issue after evidence is complete), establishing real GitHub mutation under governed conditions.

## Source References

- README.md
- SPECBRIDGE.md
- AGENTS.md
- CLAUDE.md
- .specbridge/policy.yaml
- .specbridge/context/CURRENT_GOAL.md
- .specbridge/reports/issue-115-github-evidence-loop.final-report.json
- .specbridge/audit-packets/issue-115-github-evidence-loop.audit-packet.json
- .specbridge/audits/issue-115-github-evidence-loop.chatgpt-audit.json
- .specbridge/github-evidence/issue-115-github-evidence-loop.github-mutation-evidence.json
- https://github.com/yagooyarzabaldev-ops/specbridge/issues/115
- https://github.com/yagooyarzabaldev-ops/specbridge/issues/117
- https://github.com/yagooyarzabaldev-ops/specbridge/pull/116

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
low
```

Reason:

- this task only updates repository memory and evidence after a confirmed GitHub merge
- it does not change product code, scripts, tests, workflows, dependencies, secrets, production, billing, authentication, authorization, database, or deployment automation

## Allowed Scope

```text
README.md
.specbridge/audit-packets/issue-115-github-evidence-loop.audit-packet.json
.specbridge/audit-packets/issue-117-post-merge-memory-closure.audit-packet.json
.specbridge/audits/issue-115-github-evidence-loop.chatgpt-audit.json
.specbridge/audits/issue-117-post-merge-memory-closure.chatgpt-audit.json
.specbridge/context/CURRENT_GOAL.md
.specbridge/contracts/issue-117-post-merge-memory-closure.execution.md
.specbridge/github-evidence/issue-117-post-merge-memory-closure.closure.json
.specbridge/reports/issue-115-github-evidence-loop.final-report.json
.specbridge/reports/issue-117-post-merge-memory-closure.final-report.json
.specbridge/scopes/issue-117-post-merge-memory-closure.scope.json
GitHub issue 117
GitHub pull request for this branch
```

## Blocked Scope

```text
product code
scripts/specbridge.ps1
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

- `CURRENT_GOAL.md` no longer claims issue 115 is the active phase pending GitHub gates.
- `CURRENT_GOAL.md` records issue 119 (apply-mode pilot) as the next recommended task.
- `README.md` marks the GitHub evidence loop as complete and adds the next phase.
- Issue 115 final report records PR 116 merge and CI completion.
- Issue 115 audit packet records `ci_status: passed` and `completion_status: complete`.
- Issue 115 ChatGPT/Codex audit records PR 116 CI and merge evidence.
- Issue 117 closure evidence validates locally.
- No product code, scripts, workflows, secrets, production, billing, auth, database, dependency, CI/CD security, or deployment files are changed.

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

Stop if the task requires product code changes, protected credential access, production configuration, billing, authentication security, authorization security, dependency installation, database changes, CI/CD security changes, deployment automation, or scope outside the declared paths.

## Merge Policy

Autonomous merge is allowed only after required local validations, GitHub CI, security gate, review gate, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

The final report must include summary, changed files, validations, policy result, risk result, merge status, deployment status, unresolved risks, and completion status.

## Completion Rule

This closure is complete when issue 115 post-merge evidence is updated, CURRENT_GOAL points to issue 119, README reflects the completed evidence loop, local evidence validators pass, GitHub CI passes, and the closure branch is policy-gated into main.
