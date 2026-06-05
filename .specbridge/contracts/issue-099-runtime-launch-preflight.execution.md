# Execution Contract: Issue 99 Runtime Launch Preflight

## Contract Metadata

- contract_id: issue-099-runtime-launch-preflight
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/99
- created_by: ChatGPT/Codex
- created_at: 2026-06-05
- autonomy_profile: full_autopilot
- risk_level: medium
- status: completed

## Goal

Add a deterministic `preflight-runtime-launches` CLI command that reads prepared runtime launch plans and verifies they are safe to consider for a future live operator launch.

This task must:

- read one or more `.specbridge/runtime-launches/*.runtime-launch.json` files
- confirm required slice ids are present when declared
- confirm executor write scopes do not overlap
- confirm per-launch budget stays within a configured preflight limit
- confirm launch tools are limited to a configured allowed set
- confirm every launch remains inside the plan-only execution policy boundary
- support optional file-backed JSON output under `.specbridge/preflights/`
- add validation, tests, docs, final report, audit packet, and ChatGPT/Codex audit evidence
- avoid live runtime execution

## Context

Issue 097 prepared three plan-only runtime launch artifacts for `status`, `tests`, and `docs`. Before using any of those launch plans for a future operator-controlled live slice, SpecBridge needs a deterministic preflight that can summarize the planned launches and block obvious scope, tool, budget, or execution-policy drift.

The preflight command is still preparation only. It does not launch Claude Code, launch Antigravity, execute shell commands, call GitHub, install dependencies, access secrets, touch production, or deploy.

## Source References

- README.md
- SPECBRIDGE.md
- AGENTS.md
- CLAUDE.md
- .specbridge/policy.yaml
- .specbridge/context/CURRENT_GOAL.md
- docs/specbridge-local-cli.md
- docs/specbridge-runtime-launch-plans.md
- docs/specbridge-multi-slice-live-pilot-contract.md
- scripts/specbridge.ps1
- scripts/test-specbridge-cli.ps1
- scripts/validate-runtime-launches.ps1
- .specbridge/runtime-launches/issue-097-status.runtime-launch.json
- .specbridge/runtime-launches/issue-097-tests.runtime-launch.json
- .specbridge/runtime-launches/issue-097-docs.runtime-launch.json
- https://github.com/yagooyarzabaldev-ops/specbridge/issues/99

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
medium
```

Reason:

- this task changes the local CLI and validation chain
- risk is bounded because the command is deterministic, reads repository artifacts, writes only an optional preflight JSON artifact, and does not execute any runtime plan

## Allowed Scope

```text
README.md
docs/specbridge-local-cli.md
docs/specbridge-runtime-launch-plans.md
docs/specbridge-runtime-launch-preflight.md
docs/specbridge-test-matrix.md
scripts/specbridge.ps1
scripts/specbridge-smoke.ps1
scripts/test-specbridge-cli.ps1
scripts/validate-runtime-preflights.ps1
scripts/validate-schemas.ps1
.specbridge/audit-packets/issue-099-runtime-launch-preflight.audit-packet.json
.specbridge/audits/issue-099-runtime-launch-preflight.chatgpt-audit.json
.specbridge/context/CURRENT_GOAL.md
.specbridge/contracts/issue-099-runtime-launch-preflight.execution.md
.specbridge/preflights/issue-099-runtime-launch-preflight.runtime-preflight.json
.specbridge/reports/issue-099-runtime-launch-preflight.final-report.json
.specbridge/schemas/runtime-preflight.schema.json
.specbridge/scopes/issue-099-runtime-launch-preflight.scope.json
.specbridge/standard-loop-runs/issue-099-runtime-launch-preflight.standard-loop-run.json
GitHub issue 99
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

- `preflight-runtime-launches` returns deterministic JSON with `ok`, `input_paths`, `loaded_launches`, `required_slices`, `missing_required_slices`, `duplicate_slices`, `non_overlap`, `budget`, `tools`, `execution_policy`, `blockers`, `source_files`, and `output_path`.
- The issue 097 `status`, `tests`, and `docs` launch plans pass preflight with required slices declared.
- The command rejects overlapping `exclusive_write` scopes.
- The command rejects launch plans whose `max_budget_usd` exceeds the configured preflight limit.
- The command rejects unsafe execution policy booleans.
- The command supports optional output under `.specbridge/preflights/*.runtime-preflight.json`.
- Runtime preflight artifacts validate.
- Docs explain command usage and the no-launch boundary.
- No secrets, production, billing, auth, authorization, database, dependency installation, CI/CD security, live runtime execution, or deployment files are changed.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 preflight-runtime-launches -InputPath ".specbridge/runtime-launches/issue-097-status.runtime-launch.json,.specbridge/runtime-launches/issue-097-tests.runtime-launch.json,.specbridge/runtime-launches/issue-097-docs.runtime-launch.json" -RequiredSlice status,tests,docs -AllowedTool Read,Write,Edit -MaxBudgetUsd 2.00 -OutputPath .specbridge/preflights/issue-099-runtime-launch-preflight.runtime-preflight.json -Force
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-preflights.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 validate -Profile standard
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/test-specbridge-cli.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
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

Stop if the task requires secrets, production configuration, billing, authentication security, authorization security, dependency installation, database changes, CI/CD security changes, live runtime execution, deployment automation, or scope outside the declared paths.

## Merge Policy

Autonomous merge is allowed only after required local validations, GitHub CI, security gate, review gate, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

The final report must include summary, changed files, validations, policy result, risk result, merge status, deployment status, unresolved risks, rollback notes, and completion status.

## Completion Rule

This task is complete when the preflight command, runtime preflight validator, docs, issue 099 preflight artifact, final report, audit packet, ChatGPT/Codex audit, local validations, GitHub CI, review gate, and security gate pass and the branch is policy-gated into main.
