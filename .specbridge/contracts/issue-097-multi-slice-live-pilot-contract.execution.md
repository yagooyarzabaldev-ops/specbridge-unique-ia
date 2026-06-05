# Execution Contract: Issue 97 Multi-Slice Live Pilot Contract

## Contract Metadata

- contract_id: issue-097-multi-slice-live-pilot-contract
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/97
- created_by: ChatGPT/Codex
- created_at: 2026-06-05
- autonomy_profile: full_autopilot
- risk_level: medium
- status: completed

## Goal

Use `standard-loop-orchestrate` and its `next_contract_seed` to prepare the next governed multi-slice live pilot contract with non-overlapping executor scopes.

This task must:

- write the issue 097 Standard Loop artifact from the seed
- define a three-slice live pilot handoff
- generate executor packets for each slice
- generate plan-only runtime launch artifacts for each slice
- document the prepared launch boundary
- produce final report, audit packet, and ChatGPT/Codex audit evidence
- avoid live runtime execution

## Context

Issue 095 added `next_contract_seed` to the Standard Loop orchestrator. The seed for `issue-097-multi-slice-live-pilot-contract` declares the expected contract, scope, report, audit, ChatGPT audit, and standard-loop-run paths.

This issue exercises that seed by creating the first prepared multi-slice live pilot contract. The output is intentionally preparatory: runtime launches may be ready for a future operator launch, but this contract does not launch Claude Code, Antigravity, shell commands, deployment, dependencies, GitHub operations from the CLI, or production changes.

## Source References

- README.md
- SPECBRIDGE.md
- AGENTS.md
- CLAUDE.md
- .specbridge/policy.yaml
- .specbridge/context/CURRENT_GOAL.md
- docs/specbridge-standard-loop-orchestrator.md
- docs/specbridge-v5-live-parallel-pilot-boundary.md
- docs/specbridge-runtime-launch-plans.md
- docs/specbridge-live-antigravity-executor-handoff.md
- scripts/specbridge.ps1
- scripts/validate-executor-packets.ps1
- scripts/validate-runtime-launches.ps1
- https://github.com/yagooyarzabaldev-ops/specbridge/issues/97

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
medium
```

Reason:

- this task creates runtime handoff and launch planning artifacts
- risk is bounded because the generated runtime launches are plan-only and explicitly record that they do not launch Claude Code, launch Antigravity, execute shell, install dependencies, touch secrets, touch production, or deploy

## Allowed Scope

```text
README.md
docs/specbridge-multi-slice-live-pilot-contract.md
.specbridge/audit-packets/issue-097-multi-slice-live-pilot-contract.audit-packet.json
.specbridge/audits/issue-097-multi-slice-live-pilot-contract.chatgpt-audit.json
.specbridge/context/CURRENT_GOAL.md
.specbridge/contracts/issue-097-multi-slice-live-pilot-contract.execution.md
.specbridge/executor-handoffs/issue-097-multi-slice-live-pilot-contract.input.json
.specbridge/executor-packets/issue-097-multi-slice-live-pilot-contract-status.executor-packet.json
.specbridge/executor-packets/issue-097-multi-slice-live-pilot-contract-tests.executor-packet.json
.specbridge/executor-packets/issue-097-multi-slice-live-pilot-contract-docs.executor-packet.json
.specbridge/reports/issue-097-multi-slice-live-pilot-contract.final-report.json
.specbridge/runtime-launches/issue-097-status.runtime-launch.json
.specbridge/runtime-launches/issue-097-tests.runtime-launch.json
.specbridge/runtime-launches/issue-097-docs.runtime-launch.json
.specbridge/scopes/issue-097-multi-slice-live-pilot-contract.scope.json
.specbridge/standard-loop-runs/issue-097-multi-slice-live-pilot-contract.standard-loop-run.json
GitHub issue 97
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
live Claude Code launch
live Antigravity launch
runtime execution
deployment automation
production deployment
```

## Acceptance Criteria

- `standard-loop-orchestrate -TaskId issue-097-multi-slice-live-pilot-contract` produces a seed and file-backed artifact.
- The executor handoff has at least three slices.
- Executor slice `exclusive_write` paths are non-overlapping.
- Executor packets validate.
- Runtime launch plans validate.
- Runtime launch plans remain plan-only with `launches_claude=false`, `launches_antigravity=false`, `executes_shell=false`, `installs_dependencies=false`, and `deploys=false`.
- Docs explain the prepared slices and launch boundary.
- Contract, scope, final report, audit packet, ChatGPT/Codex audit, standard-loop-run, executor handoff, executor packets, and runtime launches exist.
- No secrets, production, billing, auth, authorization, database, dependency installation, CI/CD security, live runtime execution, or deployment files are changed.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 standard-loop-orchestrate -TaskId issue-097-multi-slice-live-pilot-contract
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 validate -Profile standard
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-executor-packets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-launches.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contract-scopes.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-audit-packets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-chatgpt-audits.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-security-gates.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-review-gate.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
git diff --check
```

## Stop Conditions

Stop if the task requires secrets, production configuration, billing, authentication security, authorization security, dependency installation, database changes, CI/CD security changes, live runtime execution, deployment automation, or scope outside the declared paths.

## Merge Policy

Autonomous merge is allowed only after required local validations, GitHub CI, security gate, review gate, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

The final report must include summary, changed files, validations, policy result, risk result, merge status, deployment status, unresolved risks, rollback notes, and completion status.

## Completion Rule

This task is complete when the Standard Loop artifact, contract, scope, executor handoff, executor packets, runtime launch plans, docs, final report, audit packet, ChatGPT/Codex audit, local validations, GitHub CI, review gate, and security gate pass and the branch is policy-gated into main.
