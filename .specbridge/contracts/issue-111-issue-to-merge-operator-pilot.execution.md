# Execution Contract: Issue 111 Issue-to-Merge Operator Pilot

## Contract Metadata

- contract_id: issue-111-issue-to-merge-operator-pilot
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/111
- created_by: ChatGPT/Codex
- created_at: 2026-06-05
- autonomy_profile: full_autopilot
- risk_level: low
- status: completed

## Goal

Pilot the deterministic plan-only `issue-to-merge-plan` operator on a safe documentation and evidence task before any future GitHub-mutating operator mode is considered.

The pilot must prove that the new operator can describe the governed issue-to-merge path for a real issue, write a file-backed run artifact, preserve policy boundaries, and leave repository memory and audit evidence ready for PR, CI, review, and policy-gated merge.

## Context

Issue 109 completed the first governed issue-to-merge operator surface. That command is intentionally plan-only: it emits deterministic JSON and may write only `.specbridge/issue-to-merge-runs/*.issue-to-merge-run.json` artifacts.

The next task recorded in repository memory was to pilot that operator with a small safe dry-run or documentation-only task before authorizing any GitHub-mutating operator mode. Issue 111 is that pilot.

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
- scripts/test-specbridge-cli.ps1
- .specbridge/issue-to-merge-runs/issue-109-governed-issue-to-merge-operator.issue-to-merge-run.json
- .specbridge/reports/issue-109-governed-issue-to-merge-operator.final-report.json
- https://github.com/yagooyarzabaldev-ops/specbridge/issues/111

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
low
```

Reason:

- the task changes documentation, repository memory, and evidence artifacts only
- no product runtime behavior or CLI implementation changes are required
- the operator remains plan-only
- GitHub mutation from the operator command, live runtime launch, dependency installation, CI/CD security changes, deployment, secrets, production, billing, auth, authorization, and database changes remain blocked

## Allowed Scope

```text
README.md
docs/specbridge-issue-to-merge-operator.md
.specbridge/audit-packets/issue-111-issue-to-merge-operator-pilot.audit-packet.json
.specbridge/audits/issue-111-issue-to-merge-operator-pilot.chatgpt-audit.json
.specbridge/context/CURRENT_GOAL.md
.specbridge/contracts/issue-111-issue-to-merge-operator-pilot.execution.md
.specbridge/issue-to-merge-runs/issue-111-issue-to-merge-operator-pilot.issue-to-merge-run.json
.specbridge/reports/issue-111-issue-to-merge-operator-pilot.final-report.json
.specbridge/scopes/issue-111-issue-to-merge-operator-pilot.scope.json
GitHub issue 111
GitHub pull request for this branch
```

## Blocked Scope

```text
scripts/specbridge.ps1
scripts/test-specbridge-cli.ps1
.github/workflows/**
.env
.env.*
secrets/**
infra/prod/**
dependency manifests
live Claude Code launch
live Antigravity launch
runtime launch execution
GitHub mutation from the issue-to-merge-plan command
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

- GitHub issue 111 exists and describes the safe pilot goal and boundaries.
- The branch runs `issue-to-merge-plan` with `TaskId` `issue-111-issue-to-merge-operator-pilot`.
- The operator writes `.specbridge/issue-to-merge-runs/issue-111-issue-to-merge-operator-pilot.issue-to-merge-run.json`.
- The run artifact records plan-only mode, the issue reference, evidence paths, local gates, GitHub gates, merge conditions, post-merge memory closure, policy boundaries, and command boundary.
- README and `docs/specbridge-issue-to-merge-operator.md` record the safe pilot result and clarify that GitHub-mutating behavior remains future dedicated work.
- `CURRENT_GOAL.md` advances from issue 109 to issue 111 and records the next recommended task after the pilot.
- Final report, audit packet, and ChatGPT/Codex audit validate.
- Local standard validation, CLI tests, smoke validation, security gate, review gate, and whitespace validation pass.
- GitHub CI passes before merge.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 issue-to-merge-plan -TaskId issue-111-issue-to-merge-operator-pilot -Title "Pilot issue-to-merge operator" -Goal "Pilot the deterministic plan-only SpecBridge issue-to-merge operator with a safe documentation and evidence task before any future GitHub-mutating operator mode." -RelatedIssue https://github.com/yagooyarzabaldev-ops/specbridge/issues/111 -OutputPath .specbridge/issue-to-merge-runs/issue-111-issue-to-merge-operator-pilot.issue-to-merge-run.json -Force
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

Stop if the task requires changing `scripts/specbridge.ps1`, changing workflow files, GitHub mutation from the `issue-to-merge-plan` command, live runtime launch, secrets, production configuration, billing, authentication security, authorization security, dependency installation, database changes, CI/CD security changes, deployment automation, or scope outside the declared paths.

Stop if the operator pilot cannot preserve the plan-only boundary.

## Merge Policy

Autonomous merge is allowed only after required local validations, GitHub CI, security gate, review gate, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

The final report must use the repository final-report schema and include summary, changed files, validations, policy result, risk result, unresolved risks, merge status, deployment status, and completion status.

## Completion Rule

This task is complete when the issue-to-merge run artifact, docs, memory, final report, audit packet, ChatGPT/Codex audit, and local validations pass. It is repository-complete when its PR passes GitHub CI and merges under policy gates.
