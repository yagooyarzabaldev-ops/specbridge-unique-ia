# Execution Contract: Issue 93 Standard Loop Orchestrator

## Contract Metadata

- contract_id: issue-093-standard-loop-orchestrator
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/93
- created_by: ChatGPT/Codex
- created_at: 2026-06-04
- autonomy_profile: full_autopilot
- risk_level: medium
- status: completed

## Goal

Add the first deterministic one-command Standard Loop orchestrator so operators and agents can ask SpecBridge for the governed issue-to-merge sequence from repository files instead of relying on chat memory.

This task must:

- add `standard-loop-orchestrate` to the local CLI
- cover stdout and output-path behavior in CLI tests
- document the command
- produce repository evidence for issue 093
- avoid live runtime expansion

## Context

SpecBridge already has Standard Loop v1, `standard-loop-status`, templates, schemas, validators, CI authority docs, runtime launch/result/summary evidence, audit packets, ChatGPT/Codex audits, and GitHub CI gates.

The missing operator surface is one command that assembles the issue-to-merge sequence from repository files and reports the current phase, next recommended action, phases, gates, latest artifacts, and policy boundaries.

This command is intentionally plan-only. It does not launch Claude Code, launch Antigravity, call GitHub, install dependencies, deploy, or mutate repository state except for an explicitly requested output artifact path.

## Source References

- README.md
- SPECBRIDGE.md
- AGENTS.md
- CLAUDE.md
- .specbridge/policy.yaml
- .specbridge/context/CURRENT_GOAL.md
- docs/specbridge-standard-loop-v1.md
- docs/specbridge-standard-loop-feature-pilot.md
- docs/specbridge-ci-authority-standard.md
- scripts/specbridge.ps1
- scripts/test-specbridge-cli.ps1
- https://github.com/yagooyarzabaldev-ops/specbridge/issues/93

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
- risk is bounded because the command is deterministic, file-backed, plan-only, and does not launch live runtimes, call GitHub, install dependencies, change workflows, or deploy

## Allowed Scope

```text
README.md
docs/specbridge-standard-loop-v1.md
docs/specbridge-standard-loop-orchestrator.md
scripts/specbridge.ps1
scripts/test-specbridge-cli.ps1
.specbridge/audit-packets/issue-093-standard-loop-orchestrator.audit-packet.json
.specbridge/audits/issue-093-standard-loop-orchestrator.chatgpt-audit.json
.specbridge/context/CURRENT_GOAL.md
.specbridge/contracts/issue-093-standard-loop-orchestrator.execution.md
.specbridge/reports/issue-093-standard-loop-orchestrator.final-report.json
.specbridge/scopes/issue-093-standard-loop-orchestrator.scope.json
.specbridge/standard-loop-runs/issue-093-standard-loop-orchestrator.standard-loop-run.json
GitHub issue 93
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

- `scripts/specbridge.ps1` supports `standard-loop-orchestrate`.
- The command returns deterministic JSON with Standard Loop phases, required local gates, required GitHub gates, current repository phase, next recommended action, latest artifacts, missing required paths, and policy boundaries.
- The command exits `0` when required Standard Loop paths exist and `1` when any are missing.
- The command can write `.specbridge/standard-loop-runs/*.standard-loop-run.json` when `-OutputPath` is supplied.
- `scripts/test-specbridge-cli.ps1` covers stdout and output-path behavior.
- README and docs mention the command.
- Issue 093 output artifact and closure evidence validate locally.
- No secrets, production, billing, auth, authorization, database, dependency installation, CI/CD security, live launch expansion, or deployment files are changed.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 standard-loop-orchestrate
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 standard-loop-orchestrate -TaskId issue-093-standard-loop-orchestrator -OutputPath .specbridge/standard-loop-runs/issue-093-standard-loop-orchestrator.standard-loop-run.json -Force
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

The final report must include summary, changed files, validations, policy result, risk result, merge status, deployment status, unresolved risks, and completion status.

## Completion Rule

This task is complete when the CLI command, tests, docs, output artifact, final report, audit packet, ChatGPT/Codex audit, local validations, GitHub CI, review gate, and security gate pass and the branch is policy-gated into main.
