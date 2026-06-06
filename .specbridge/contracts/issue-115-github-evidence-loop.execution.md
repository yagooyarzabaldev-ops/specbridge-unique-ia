# Execution Contract: Issue 115 GitHub Evidence Loop Pilot

## Contract Metadata

- contract_id: issue-115-github-evidence-loop
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/115
- created_by: ChatGPT/Codex
- created_at: 2026-06-06
- autonomy_profile: full_autopilot
- risk_level: medium
- status: completed

## Goal

Run a small end-to-end issue-to-merge task using the new `issue-to-merge-github` dry-run artifact as the declared GitHub connector action envelope, then compare the recorded envelope with governed real GitHub lifecycle evidence.

## Context

Issue 109 added `issue-to-merge-plan` as a plan-only operator.

Issue 111 piloted the plan-only operator on a safe documentation and evidence task.

Issue 113 added `issue-to-merge-github` as a bounded GitHub mutation operator surface. The command remains dry-run by default, records explicit connector action envelopes, and blocks apply mode unless force, confirmation, and declared local/GitHub gate evidence are present.

Issue 115 is the next recommended task after issue 113: use the dry-run mutation envelope as the declared action plan for one small governed GitHub lifecycle pilot, while keeping repository-local command behavior dry-run and preserving policy gates.

## Source References

- README.md
- SPECBRIDGE.md
- AGENTS.md
- CLAUDE.md
- .specbridge/policy.yaml
- .specbridge/context/CURRENT_GOAL.md
- docs/specbridge-issue-to-merge-operator.md
- docs/specbridge-local-cli.md
- scripts/specbridge.ps1
- .specbridge/issue-to-merge-runs/issue-113-bounded-github-mutation-operator.github-mutation-run.json
- .specbridge/reports/issue-113-bounded-github-mutation-operator.final-report.json
- https://github.com/yagooyarzabaldev-ops/specbridge/issues/115

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
medium
```

Reason:

- the task uses real GitHub issue and pull request lifecycle actions through governed connector calls
- the repository-local `issue-to-merge-github` command remains dry-run and performs no GitHub calls
- merge remains gated by local validation, GitHub CI, security gate, review gate, and ChatGPT/Codex audit
- secrets, production, billing, auth, authorization, database, dependency installation, CI/CD security changes, and deployment remain blocked

## Allowed Scope

```text
README.md
docs/specbridge-issue-to-merge-operator.md
.specbridge/audit-packets/issue-115-github-evidence-loop.audit-packet.json
.specbridge/audits/issue-115-github-evidence-loop.chatgpt-audit.json
.specbridge/context/CURRENT_GOAL.md
.specbridge/contracts/issue-115-github-evidence-loop.execution.md
.specbridge/github-evidence/issue-115-github-evidence-loop.github-mutation-evidence.json
.specbridge/issue-to-merge-runs/issue-115-github-evidence-loop.github-mutation-run.json
.specbridge/reports/issue-115-github-evidence-loop.final-report.json
.specbridge/scopes/issue-115-github-evidence-loop.scope.json
GitHub issue 115
GitHub pull request for this branch
```

## Blocked Scope

```text
.github/workflows/**
.env
.env.*
secrets/**
infra/prod/**
dependency manifests
live Claude Code launch
live Antigravity launch
runtime launch execution
secret or token access
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

- `issue-to-merge-github` runs in dry-run mode for issue 115 and writes `.specbridge/issue-to-merge-runs/issue-115-github-evidence-loop.github-mutation-run.json`.
- The dry-run artifact records the GitHub connector action envelope, selected operations, required evidence, preconditions, stop conditions, merge conditions, and policy boundaries.
- A bounded GitHub evidence artifact compares the dry-run envelope with the real issue and pull request lifecycle evidence available before merge.
- The evidence artifact records the issue URL, planned branch, PR URL when opened, head SHA, required GitHub checks, CI observation status, merge gate status, and issue closure expectation.
- README, issue-to-merge operator docs, and CURRENT_GOAL record issue 115 and the evidence-loop standard.
- Final report, audit packet, and ChatGPT/Codex audit validate.
- Local standard validation, smoke validation, CLI tests, security gate, review gate, and whitespace validation pass.
- GitHub CI passes before merge.
- Merge and issue closure evidence are confirmed after PR merge by GitHub state; no pre-merge artifact may claim post-merge facts.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 issue-to-merge-github -TaskId issue-115-github-evidence-loop -Title "Pilot issue-to-merge GitHub evidence loop" -Goal "Run a small end-to-end issue-to-merge task using the dry-run GitHub mutation envelope and compare it with governed real GitHub lifecycle evidence." -RelatedIssue https://github.com/yagooyarzabaldev-ops/specbridge/issues/115 -OutputPath .specbridge/issue-to-merge-runs/issue-115-github-evidence-loop.github-mutation-run.json -Force
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

Stop if repository evidence would need to claim GitHub merge or issue closure before those facts exist.

## Merge Policy

Autonomous merge is allowed only after required local validations, GitHub CI, security gate, review gate, ChatGPT/Codex audit, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

The final report must use the repository final-report schema and include summary, changed files, validations, policy result, risk result, unresolved risks, merge status, deployment status, and completion status.

## Completion Rule

This task is locally complete when the dry-run mutation envelope, GitHub evidence artifact, docs, memory, final report, audit packet, ChatGPT/Codex audit, and local validations pass. It is repository-complete when its PR passes GitHub CI, merges under policy gates, and GitHub closes issue 115 as completed.
