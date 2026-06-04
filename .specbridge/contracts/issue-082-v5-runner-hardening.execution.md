# Execution Contract: Issue 82 V5 Runner Hardening

## Contract Metadata

- contract_id: issue-082-v5-runner-hardening
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/82
- created_by: ChatGPT/Codex
- created_at: 2026-06-04
- autonomy_profile: full_autopilot
- risk_level: medium
- status: completed

## Goal

Close the second V5 live autonomy pilot state after PR 81 merge and harden the live runtime runner defaults discovered during issue 080.

This task must:

- mark issue 080 repository memory as fully complete after merge and CI success
- update the current goal to the next runner-hardening state
- raise the default bounded live runtime budget from `0.25` to `2.00`
- make runtime diagnostic previews validate deterministically when Claude output contains non-ASCII or multibyte text
- add focused test coverage for the new default and diagnostic preview behavior
- ignore local-only agent and Claude settings paths without committing their contents

## Context

Issue 080 completed the second V5 live autonomy pilot and PR 81 was merged into `main` with GitHub CI passing. The merge left repository memory in a pre-merge state, including `complete_pending_pr_ci` final report fields and an active scope manifest.

The pilot also exposed two runner hardening needs:

- `MaxBudgetUsd` default `0.25` was too low for a live implementation slice and caused a budget-only failure before product changes.
- runtime execution diagnostic previews could become schema-invalid when successful Claude output contained multibyte characters.

## Source References

- README.md
- SPECBRIDGE.md
- AGENTS.md
- CLAUDE.md
- .specbridge/policy.yaml
- .specbridge/context/CURRENT_GOAL.md
- .specbridge/contracts/issue-080-second-v5-live-autonomy-pilot.execution.md
- .specbridge/reports/issue-080-second-v5-live-autonomy-pilot.final-report.json
- .specbridge/audit-packets/issue-080-second-v5-live-autonomy-pilot.audit-packet.json
- .specbridge/audits/issue-080-second-v5-live-autonomy-pilot.chatgpt-audit.json
- .specbridge/scopes/issue-080-second-v5-live-autonomy-pilot.scope.json
- docs/specbridge-runtime-launch-plans.md
- docs/specbridge-runtime-runner.md
- scripts/specbridge.ps1
- scripts/test-specbridge-cli.ps1
- https://github.com/yagooyarzabaldev-ops/specbridge/issues/82
- https://github.com/yagooyarzabaldev-ops/specbridge/pull/81

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
medium
```

Reason:

- this task changes runtime launch defaults and diagnostic preview behavior
- it updates repository evidence used for merge and audit decisions
- it does not touch secrets, production, billing, authentication, authorization, database, dependencies, CI/CD security, or deployment automation

## Allowed Scope

```text
.gitignore
.specbridge/audit-packets/issue-080-second-v5-live-autonomy-pilot.audit-packet.json
.specbridge/audit-packets/issue-082-v5-runner-hardening.audit-packet.json
.specbridge/audits/issue-080-second-v5-live-autonomy-pilot.chatgpt-audit.json
.specbridge/audits/issue-082-v5-runner-hardening.chatgpt-audit.json
.specbridge/context/CURRENT_GOAL.md
.specbridge/contracts/issue-082-v5-runner-hardening.execution.md
.specbridge/reports/issue-080-second-v5-live-autonomy-pilot.final-report.json
.specbridge/reports/issue-082-v5-runner-hardening.final-report.json
.specbridge/scopes/issue-080-second-v5-live-autonomy-pilot.scope.json
.specbridge/scopes/issue-082-v5-runner-hardening.scope.json
README.md
docs/specbridge-runtime-launch-plans.md
docs/specbridge-runtime-runner.md
docs/specbridge-test-results.md
scripts/specbridge.ps1
scripts/test-specbridge-cli.ps1
GitHub issue 82
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
database changes
```

## Acceptance Criteria

- Issue 080 scope status is `completed`.
- Issue 080 final report, audit packet, and ChatGPT/Codex audit reflect PR 81 merge and GitHub CI success.
- `CURRENT_GOAL.md` no longer describes issue 080 as active work.
- `prepare-runtime-launch` defaults `MaxBudgetUsd` to `2.00`.
- CLI tests assert the default runtime launch budget is `2.00`.
- `execute-runtime-launch` diagnostic previews normalize non-ASCII output before truncation so `preview_length` matches validator semantics and `text.Length` never exceeds `max_length`.
- CLI tests cover a failed fake Claude invocation with non-ASCII stdout and validate the produced runtime execution artifact.
- Runtime runner docs describe the bounded ASCII-normalized diagnostic preview behavior.
- Runtime launch docs describe the `2.00` default budget and still allow explicit overrides up to `10`.
- `.gitignore` keeps local `.agents/` and `.claude/settings.local.json` out of committed task scope without committing their contents.
- Local validation passes for contracts, scopes, schemas, final reports, audit packets, ChatGPT audits, standard profile, CLI tests, negative validations, smoke, security gate, review gate, and git diff whitespace.
- GitHub CI and deterministic review gates pass before merge.
- No secrets, production configuration, billing, auth security, dependency installation, database changes, CI/CD weakening, or deployment automation are involved.

## Required Validations

```powershell
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

Stop if the task requires workflow security changes, secrets, production configuration, billing, authentication or authorization security changes, dependency installation, database changes, deployment automation, protected file changes, or scope outside the declared paths.

## Merge Policy

Autonomous merge is allowed only after required local validations, GitHub CI, deterministic review report, security gate, review gate, audit packet validation, ChatGPT/Codex audit validation, scope validation, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

The final report must include summary, changed files, validations, policy result, risk result, merge status, deployment status, unresolved risks, and rollback notes if applicable.

## Completion Rule

This task is complete only when issue 080 post-merge evidence is closed, runner hardening is implemented and tested, local gates pass, GitHub CI passes, and policy-gated merge succeeds.
