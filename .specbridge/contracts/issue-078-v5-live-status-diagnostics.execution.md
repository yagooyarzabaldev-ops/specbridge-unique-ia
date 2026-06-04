# Execution Contract: Issue 78 V5 Live Status and Runner Diagnostics

## Contract Metadata

- contract_id: issue-078-v5-live-status-diagnostics
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/78
- created_by: ChatGPT/Codex
- created_at: 2026-06-03
- autonomy_profile: full_autopilot
- risk_level: medium
- status: ready_for_execution

## Goal

Close the completed V5 live pilot as repository memory, improve safe diagnostics for live runtime execution failures, and add a deterministic `v5-live-status` CLI command.

The work must happen in this order:

1. Update repository memory so the completed V5 live pilot is no longer described as the active unfinished phase.
2. Add bounded redacted failure diagnostics to runtime execution artifacts produced by `execute-runtime-launch`.
3. Add `v5-live-status` so future operators can see live pilot completion, slice outcomes, coordinator remediation, and remaining risks without reading every artifact manually.

## Context

The V5 live parallel pilot was merged in PR #77. It proved docs and tests live executor slices, but the CLI implementation live executor failed twice with exit code `1` and no stderr before coordinator remediation completed the scoped product change.

This contract addresses that autonomy gap without launching new live Claude Code sessions.

## Source References

- README.md
- SPECBRIDGE.md
- AGENTS.md
- CLAUDE.md
- .specbridge/policy.yaml
- .specbridge/context/CURRENT_GOAL.md
- .specbridge/contracts/issue-076-v5-live-parallel-pilot.execution.md
- .specbridge/reports/issue-076-v5-live-parallel-pilot.final-report.json
- .specbridge/audits/issue-076-v5-live-parallel-pilot.chatgpt-audit.json
- .specbridge/runtime-executions/issue-076-cli-capability.runtime-execution.json
- .specbridge/runtime-executions/issue-076-cli-capability-retry-1.runtime-execution.json
- scripts/specbridge.ps1
- scripts/test-specbridge-cli.ps1
- scripts/validate-runtime-executions.ps1
- .specbridge/schemas/runtime-execution.schema.json
- docs/specbridge-runtime-runner.md
- docs/specbridge-test-results.md
- https://github.com/yagooyarzabaldev-ops/specbridge/issues/78

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
medium
```

Reason:

- this task changes a runtime execution artifact contract
- it changes CLI behavior and tests
- it updates repository status memory
- it does not launch live executors, change CI/CD security, access secrets, install dependencies, touch production, auth, billing, database, or deploy

## Allowed Scope

```text
.specbridge/audit-packets/issue-078-v5-live-status-diagnostics.audit-packet.json
.specbridge/audits/issue-078-v5-live-status-diagnostics.chatgpt-audit.json
.specbridge/context/CURRENT_GOAL.md
.specbridge/contracts/issue-078-v5-live-status-diagnostics.execution.md
.specbridge/reports/issue-078-v5-live-status-diagnostics.final-report.json
.specbridge/scopes/issue-076-v5-live-parallel-pilot.scope.json
.specbridge/scopes/issue-078-v5-live-status-diagnostics.scope.json
.specbridge/schemas/runtime-execution.schema.json
README.md
docs/specbridge-runtime-runner.md
docs/specbridge-test-results.md
docs/specbridge-v5-live-status.md
scripts/specbridge.ps1
scripts/test-specbridge-cli.ps1
scripts/validate-runtime-executions.ps1
GitHub issue 78
GitHub pull request for this branch
```

## Blocked Scope

```text
.env
.env.*
secrets/**
infra/prod/**
.github/workflows/**
package installation
dependency installation
hosted dashboard implementation
MCP server implementation
GitHub App implementation
database schema implementation
authentication implementation
authorization implementation
billing implementation
deployment automation
CI/CD permission escalation
CI/CD security weakening
branch protection weakening
raw protected credential capture
production deployment
destructive infrastructure operation
unrestricted shell execution
live Claude Code executor launch
live Antigravity executor launch
database changes
```

## Acceptance Criteria

- `CURRENT_GOAL.md` records V5 live pilot completion and identifies runner diagnostics plus second serious live pilot as the next product direction.
- The completed issue 076 scope is marked `completed` so it no longer blocks new active contracts.
- `execute-runtime-launch` artifacts include a `failure_diagnostics` object.
- `failure_diagnostics` never stores raw unbounded stdout or stderr.
- `failure_diagnostics` includes status, reason, exit code, timeout state, redaction policy, and bounded redacted stdout/stderr previews.
- Runtime execution validation accepts and validates the diagnostics object.
- The runtime execution schema documents the diagnostics object.
- `v5-live-status` exists in `scripts/specbridge.ps1`.
- `v5-live-status` reports command, ok, branch, head, live pilot contract/report/audit paths, runtime execution counts, slice outcomes, remediation status, readiness status, and next recommended action.
- CLI tests cover `v5-live-status` and dry-run `failure_diagnostics`.
- Documentation explains `v5-live-status` and safe diagnostics.
- Local validations pass for standard profile, CLI tests, negative validations, smoke, runtime execution validation, final reports, audit packets, ChatGPT audits, security gate, review gate, and git diff whitespace.
- GitHub CI and deterministic review gates pass before merge.
- No secrets, production, billing, auth security, dependency installation, database changes, CI/CD weakening, live executor launch, or deployment automation are involved.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 v5-live-status
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-executions.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contract-scopes.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-schemas.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-audit-packets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-chatgpt-audits.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 validate -Profile standard
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/test-specbridge-cli.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/test-specbridge-negative-validations.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-security-gates.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-review-gate.ps1
git diff --check
```

## Stop Conditions

Execution must stop if the task requires live Claude Code launch, live Antigravity launch, workflow security changes, secrets, production configuration, billing, authentication or authorization security changes, dependency installation, database changes, deployment automation, protected file changes, or scope outside the declared paths.

## Merge Policy

Gate-controlled automatic merge is allowed only after required local validations, GitHub CI, deterministic review report, security gate, review gate, audit packet validation, ChatGPT/Codex audit validation, scope validation, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

The final report must include summary, changed files, validations, diagnostics behavior, V5 live status behavior, policy result, risk result, merge status, deployment status, unresolved risks, and rollback notes if applicable.

## Completion Rule

This task is complete only when memory closure, diagnostics, `v5-live-status`, docs, tests, final report, audit packet, ChatGPT/Codex audit, local validations, GitHub CI, and policy-gated merge have passed.
