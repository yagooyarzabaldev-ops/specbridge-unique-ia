# Execution Contract: Issue 109 Governed Issue-to-Merge Operator

## Contract Metadata

- contract_id: issue-109-governed-issue-to-merge-operator
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/109
- created_by: ChatGPT/Codex
- created_at: 2026-06-05
- autonomy_profile: full_autopilot
- risk_level: medium
- status: completed

## Goal

Add a governed one-command issue-to-merge operator surface that reduces manual orchestration after the issue 107 pilot closure while preserving SpecBridge policy gates, auditability, and safe default behavior.

This first implementation must be deterministic, file-backed, and plan-only. It must not create GitHub issues, open pull requests, wait on CI, merge pull requests, launch Claude Code, launch Antigravity, install dependencies, change CI/CD security, touch secrets, or deploy.

## Context

Issue 107 closed the issue 097 post-preflight live pilot evidence chain and recorded the next standardization target: a governed one-command issue-to-merge operator.

The repository already has `standard-loop-orchestrate`, which records the canonical Standard Loop phases. Issue 109 turns that next target into a more operator-specific CLI surface that names the exact issue-to-merge phases, required evidence, gates, merge conditions, and post-merge memory closure requirements.

## Source References

- README.md
- SPECBRIDGE.md
- AGENTS.md
- CLAUDE.md
- .specbridge/policy.yaml
- .specbridge/context/CURRENT_GOAL.md
- .specbridge/pilot-closures/issue-107-post-preflight-live-pilot-closure.pilot-closure.json
- .specbridge/reports/issue-107-post-preflight-live-pilot-closure.final-report.json
- docs/specbridge-standard-loop-orchestrator.md
- docs/specbridge-local-cli.md
- scripts/specbridge.ps1
- scripts/test-specbridge-cli.ps1
- https://github.com/yagooyarzabaldev-ops/specbridge/issues/109

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
medium
```

Reason:

- the task changes the local CLI product surface
- the command is plan-only and writes only a local artifact
- GitHub mutation, merge, runtime launch, dependency installation, CI/CD security, deployment, secrets, production, billing, auth, authorization, and database changes remain blocked

## Allowed Scope

```text
README.md
docs/specbridge-local-cli.md
docs/specbridge-issue-to-merge-operator.md
scripts/specbridge.ps1
scripts/test-specbridge-cli.ps1
.specbridge/audit-packets/issue-109-governed-issue-to-merge-operator.audit-packet.json
.specbridge/audits/issue-109-governed-issue-to-merge-operator.chatgpt-audit.json
.specbridge/context/CURRENT_GOAL.md
.specbridge/contracts/issue-109-governed-issue-to-merge-operator.execution.md
.specbridge/issue-to-merge-runs/issue-109-governed-issue-to-merge-operator.issue-to-merge-run.json
.specbridge/reports/issue-109-governed-issue-to-merge-operator.final-report.json
.specbridge/scopes/issue-109-governed-issue-to-merge-operator.scope.json
GitHub issue 109
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
GitHub mutation from the new operator command
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

- `scripts/specbridge.ps1` exposes a governed issue-to-merge operator command.
- The command emits deterministic JSON and can write a file-backed artifact under `.specbridge/issue-to-merge-runs/*.issue-to-merge-run.json`.
- The output records task id, issue reference, branch, contract path, scope path, final report path, audit packet path, ChatGPT/Codex audit path, issue-to-merge phases, required local gates, required GitHub gates, merge conditions, post-merge memory closure requirements, policy boundaries, and command boundary.
- The command fails deterministically when a required `TaskId` is omitted.
- Tests cover the success path, output artifact path, important output fields, and the missing-TaskId failure path.
- README, local CLI docs, dedicated operator docs, and CURRENT_GOAL record issue 109 and the new standard.
- Final report, audit packet, and ChatGPT/Codex audit validate.
- Local standard validation, CLI tests, smoke validation, security gate, review gate, and whitespace validation pass.
- GitHub CI passes before merge.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 issue-to-merge-plan -TaskId issue-109-governed-issue-to-merge-operator -RelatedIssue https://github.com/yagooyarzabaldev-ops/specbridge/issues/109 -OutputPath .specbridge/issue-to-merge-runs/issue-109-governed-issue-to-merge-operator.issue-to-merge-run.json -Force
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

Stop if the task requires GitHub mutation from the new operator command, live runtime launch, secrets, production configuration, billing, authentication security, authorization security, dependency installation, database changes, CI/CD security changes, deployment automation, or scope outside the declared paths.

Stop if the operator cannot make the plan-only boundary explicit.

## Merge Policy

Autonomous merge is allowed only after required local validations, GitHub CI, security gate, review gate, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

The final report must use the repository final-report schema and include summary, changed files, validations, policy result, risk result, unresolved risks, merge status, deployment status, and completion status.

## Completion Rule

This task is complete when the issue-to-merge operator command, tests, docs, memory, issue-to-merge run artifact, final report, audit packet, ChatGPT/Codex audit, and local validations pass. It is repository-complete when its PR passes GitHub CI and merges under policy gates.
