# Execution Contract: Issue 95 Standard Loop Contract Seed

## Contract Metadata

- contract_id: issue-095-standard-loop-contract-seed
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/95
- created_by: ChatGPT/Codex
- created_at: 2026-06-04
- autonomy_profile: full_autopilot
- risk_level: medium
- status: completed

## Goal

Run a small real feature through `standard-loop-orchestrate` as the operator entry point by adding a deterministic `next_contract_seed` block to the Standard Loop orchestration output.

This task must:

- extend `standard-loop-orchestrate` with a seed for the next governed execution contract
- include deterministic repository-relative artifact paths, branch suggestion, issue reference, required evidence paths, suggested commands, and completion gates
- cover stdout and output artifact behavior in CLI tests
- document the seed
- produce issue 095 repository evidence
- preserve the plan-only command boundary

## Context

Issue 093 added the first deterministic one-command Standard Loop orchestrator. Its recorded next recommended task is to run a small real feature through `standard-loop-orchestrate` as the operator entry point, then use the resulting plan artifact to drive the next governed execution contract.

The missing feature is an explicit seed in the orchestration output that converts the plan into concrete next artifact names and commands. The seed must remain deterministic and must not run any external runtime.

## Source References

- README.md
- SPECBRIDGE.md
- AGENTS.md
- CLAUDE.md
- .specbridge/policy.yaml
- .specbridge/context/CURRENT_GOAL.md
- docs/specbridge-standard-loop-v1.md
- docs/specbridge-standard-loop-orchestrator.md
- docs/specbridge-ci-authority-standard.md
- scripts/specbridge.ps1
- scripts/test-specbridge-cli.ps1
- https://github.com/yagooyarzabaldev-ops/specbridge/issues/95

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
medium
```

Reason:

- this task changes the local CLI and CLI tests
- risk is bounded because the command remains deterministic, file-backed, plan-only, and does not launch live runtimes, call GitHub, install dependencies, change workflows, or deploy

## Allowed Scope

```text
README.md
docs/specbridge-standard-loop-v1.md
docs/specbridge-standard-loop-orchestrator.md
scripts/specbridge.ps1
scripts/test-specbridge-cli.ps1
.specbridge/audit-packets/issue-095-standard-loop-contract-seed.audit-packet.json
.specbridge/audits/issue-095-standard-loop-contract-seed.chatgpt-audit.json
.specbridge/context/CURRENT_GOAL.md
.specbridge/contracts/issue-095-standard-loop-contract-seed.execution.md
.specbridge/reports/issue-095-standard-loop-contract-seed.final-report.json
.specbridge/scopes/issue-095-standard-loop-contract-seed.scope.json
.specbridge/standard-loop-runs/issue-095-standard-loop-contract-seed.standard-loop-run.json
GitHub issue 95
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
live Claude Code launch expansion
live Antigravity launch expansion
deployment automation
production deployment
```

## Acceptance Criteria

- `scripts/specbridge.ps1 standard-loop-orchestrate -TaskId <task>` returns `next_contract_seed`.
- The seed includes task id, recommended branch, issue reference, contract path, scope path, final report path, audit packet path, ChatGPT/Codex audit path, standard-loop-run path, required evidence paths, suggested commands, and completion gates.
- Output-path artifacts include the same seed.
- `scripts/test-specbridge-cli.ps1` covers stdout and output-path seed behavior.
- README and docs mention how to use the seed to start the next governed execution contract.
- Issue 095 output artifact and closure evidence validate locally.
- No secrets, production, billing, auth, authorization, database, dependency installation, CI/CD security, live launch expansion, or deployment files are changed.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 standard-loop-orchestrate -TaskId issue-095-standard-loop-contract-seed
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 standard-loop-orchestrate -TaskId issue-095-standard-loop-contract-seed -OutputPath .specbridge/standard-loop-runs/issue-095-standard-loop-contract-seed.standard-loop-run.json -Force
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 validate -Profile standard
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/test-specbridge-cli.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/test-specbridge-negative-validations.ps1
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

Stop if the task requires secrets, production configuration, billing, authentication security, authorization security, dependency installation, database changes, CI/CD security changes, live launch expansion, deployment automation, or scope outside the declared paths.

## Merge Policy

Autonomous merge is allowed only after required local validations, GitHub CI, security gate, review gate, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

The final report must include summary, changed files, validations, policy result, risk result, merge status, deployment status, unresolved risks, rollback notes, and completion status.

## Completion Rule

This task is complete when the CLI command, tests, docs, output artifact, final report, audit packet, ChatGPT/Codex audit, local validations, GitHub CI, review gate, and security gate pass and the branch is policy-gated into main.
