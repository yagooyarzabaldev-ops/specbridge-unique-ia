# Execution Contract: Issue 119 Apply-Mode GitHub Operator Pilot

## Contract Metadata

- contract_id: issue-119-apply-mode-github-operator-pilot
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/119
- created_by: Claude Code / SpecBridge coordinator
- created_at: 2026-06-06
- autonomy_profile: full_autopilot
- risk_level: medium
- status: ready_for_execution

## Goal

Add real GitHub mutation execution to `issue-to-merge-github` apply mode for a single low-risk operation: `issue_close`. When all local and GitHub evidence gates pass, the command calls `gh issue close` using the declared issue reference and records the real outcome.

## Context

Issue 113 added `issue-to-merge-github` with dry-run only. Apply mode was defined architecturally but not implemented: all gate validations ran, but no GitHub call was made (`github_calls_performed = $false` regardless of mode).

Issue 115 piloted the dry-run evidence loop and proved the connector action envelope works end-to-end.

Issue 117 closed repository memory after PR 116 merged.

Issue 119 is the first real GitHub mutation: `gh issue close` executed only when all evidence gates pass and the operator is invoked with explicit confirmation flags. This keeps the blast radius to one low-risk reversible operation.

## Source References

- README.md
- SPECBRIDGE.md
- AGENTS.md
- CLAUDE.md
- .specbridge/policy.yaml
- .specbridge/context/CURRENT_GOAL.md
- docs/specbridge-issue-to-merge-operator.md
- scripts/specbridge.ps1
- scripts/test-specbridge-cli.ps1
- .specbridge/contracts/issue-115-github-evidence-loop.execution.md
- https://github.com/yagooyarzabaldev-ops/specbridge/issues/119

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
medium
```

Reason:

- the task adds a real `gh issue close` call gated by explicit evidence validation
- the operation is low-risk and reversible (a closed issue can be reopened)
- secrets, production, billing, auth, authorization, database, dependency installation, CI/CD security changes, and deployment remain blocked
- apply mode requires `-Force -ConfirmGithubMutation -EvidencePath` and a validated evidence file

## Allowed Scope

```text
README.md
docs/specbridge-issue-to-merge-operator.md
scripts/specbridge.ps1
scripts/test-specbridge-cli.ps1
.specbridge/audit-packets/issue-119-apply-mode-github-operator-pilot.audit-packet.json
.specbridge/audits/issue-119-apply-mode-github-operator-pilot.chatgpt-audit.json
.specbridge/context/CURRENT_GOAL.md
.specbridge/contracts/issue-119-apply-mode-github-operator-pilot.execution.md
.specbridge/github-evidence/issue-119-apply-mode-github-operator-pilot.github-mutation-evidence.json
.specbridge/issue-to-merge-runs/issue-119-apply-mode-github-operator-pilot.github-mutation-run.json
.specbridge/reports/issue-119-apply-mode-github-operator-pilot.final-report.json
.specbridge/scopes/issue-119-apply-mode-github-operator-pilot.scope.json
GitHub issue 119
GitHub pull request for this branch
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
live Claude Code launch
live Antigravity launch
```

## Acceptance Criteria

- `issue-to-merge-github -MutationMode apply -GithubOperation issue_close -Force -ConfirmGithubMutation -EvidencePath <path>` calls `gh issue close` when all evidence gates pass and records `github_calls_performed = true`.
- When evidence gates are blocked (any boolean field is false), the command records `apply_allowed = false` and `apply_blockers` without calling `gh`.
- When `-GithubOperation` is not `issue_close` in apply mode, the command returns `apply_allowed = false` with a blocker explaining only `issue_close` is enabled for apply-mode pilot.
- `RelatedIssue` URL must be a valid GitHub issue URL; the issue number is extracted from it.
- A `github_mutation_result` field records the `gh` command exit code and status.
- CLI tests cover: apply-mode with all gates passed (using a test fixture evidence file), apply-mode with a blocker, apply-mode with unsupported operation.
- Local standard validation, CLI tests, smoke validation, security gate, review gate, and whitespace validation pass.
- GitHub CI passes before merge.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 validate -Profile standard
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/test-specbridge-cli.ps1
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

Stop if the task requires accessing secrets, storing credentials, changing workflow security controls, changing production, changing billing, changing authentication or authorization security, installing dependencies, changing databases, launching Claude Code, launching Antigravity, deploying, or touching scope outside the declared paths.

## Merge Policy

Autonomous merge is allowed only after required local validations, GitHub CI, security gate, review gate, ChatGPT/Codex audit, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

The final report must include summary, changed files, validations, policy result, risk result, unresolved risks, merge status, deployment status, and completion status.

## Completion Rule

This task is locally complete when the CLI changes, tests, docs, evidence artifacts, final report, audit packet, and ChatGPT/Codex audit pass local validations. It is repository-complete when its PR passes GitHub CI, merges under policy gates, and GitHub closes issue 119.
