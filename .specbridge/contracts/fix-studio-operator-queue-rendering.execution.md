# Execution Contract: Fix Studio Operator Queue Rendering

## Contract Metadata

- contract_id: fix-studio-operator-queue-rendering
- run_id: sb-20260610-0200abcd
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/200
- created_by: ChatGPT
- created_at: 2026-06-10
- autonomy_profile: full_autopilot
- risk_level: low
- status: ready_for_execution

## Goal

Fix `generate-studio-dashboard` so the Studio Operator Queue section renders local `specbridge-next-task` state instead of falling back to `Operator queue state unavailable` when the queue command is available. Preserve the operator decision model: GitHub issues are storage, `.specbridge/policies/operator-task-decisions.json` is authoritative for eligibility, and issue #194 remains excluded as `not_planned`.

## Context

The operator queue hygiene work already added the offline `specbridge-next-task` selector and a Studio Operator Queue section. In practice, Studio could still show `Operator queue state unavailable` because the dashboard function invoked the nested CLI through the library script path instead of the entrypoint path. This task may add a focused Studio helper and loader wiring, plus regression coverage, but it must not change operator task decisions or revive the rejected digital twin task.

## Source References

- `scripts/specbridge.ps1` - CLI entrypoint and library loading order.
- `scripts/lib/dashboards.ps1` - Studio dashboard generation and Operator Queue section.
- `scripts/lib/intake-doctor.ps1` - `specbridge-next-task` command implementation.
- `.specbridge/policies/operator-task-decisions.json` - authoritative operator exclusion registry, including issue #194.
- `scripts/test-specbridge-cli.ps1` - CLI regression suite and Studio dashboard checks.

## Risk Level

Low. The change is local PowerShell dashboard rendering and test coverage only. It does not access secrets, production configuration, billing, authentication, authorization, databases, deployment automation, dependency installation, or CI/CD security controls.

## Autonomy Profile

```text
full_autopilot
```

## Allowed Scope

```text
.specbridge/contracts/fix-studio-operator-queue-rendering.execution.md
.specbridge/scopes/fix-studio-operator-queue-rendering.scope.json
.specbridge/reports/fix-studio-operator-queue-rendering.final-report.json
.specbridge/audit-packets/fix-studio-operator-queue-rendering.audit-packet.json
.specbridge/audits/fix-studio-operator-queue-rendering.chatgpt-audit.json
scripts/specbridge.ps1
scripts/lib/dashboards.ps1
scripts/lib/studio-queue-fix.ps1
scripts/test-specbridge-cli.ps1
docs/specbridge-studio.html
```

## Blocked Scope

```text
.github/workflows/**
.env
.env.*
secrets/**
infra/prod/**
database changes
authentication implementation
authorization implementation
billing implementation
dependency installation
deployment automation
production deployment
operator decision registry changes
digital twin implementation
issue #194 lifecycle changes
```

## Acceptance Criteria

1. `generate-studio-dashboard` renders Operator Queue state from local repository evidence when `specbridge-next-task` succeeds.
2. The Operator Queue section shows eligible task count, excluded issue `#194`, decision `not_planned`, and recommended action.
3. The generated Studio dashboard no longer emits `Operator queue state unavailable` when queue state is available.
4. Required library loading remains strict for core SpecBridge libraries and optional only for the focused Studio queue helper.
5. Regression coverage fails if the Operator Queue falls back to unavailable state.
6. Full SpecBridge smoke remains green locally and in GitHub Actions.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contract-scopes.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/test-specbridge-cli.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
git diff --check
```

## Stop Conditions

Stop if the task requires secrets, production configuration, billing, authentication security, authorization security, database changes, deployment automation, dependency installation, CI/CD security changes, changing the operator decision registry, closing or reviving issue #194, or implementing the digital twin.

## Merge Policy

Autonomous merge is allowed only after required local validations, GitHub CI, security gate, review gate, no protected file changes, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

Write `.specbridge/reports/fix-studio-operator-queue-rendering.final-report.json`, `.specbridge/audit-packets/fix-studio-operator-queue-rendering.audit-packet.json`, and `.specbridge/audits/fix-studio-operator-queue-rendering.chatgpt-audit.json`. The report must state changed files, validations, policy result, merge status, deployment status, unresolved risks, and rollback notes.

## Completion Rule

Task is complete when the Studio Operator Queue renders from local queue state, issue #194 remains excluded, all required validations pass, GitHub checks pass on PR #200, and the PR is merged or explicitly left open with the remaining blocker recorded.
