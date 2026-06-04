# Execution Contract: Issue 80 Second V5 Live Autonomy Pilot

## Contract Metadata

- contract_id: issue-080-second-v5-live-autonomy-pilot
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/80
- created_by: ChatGPT/Codex
- created_at: 2026-06-04
- autonomy_profile: full_autopilot
- risk_level: medium
- status: ready_for_execution

## Goal

Run the second V5 live autonomy pilot with three live Claude Code executor slices and no coordinator remediation.

The pilot implements one small product behavior change: `v5-autonomy-status`, a deterministic local CLI status command that reports the target autonomy standard for live V5 execution.

The command must make the next standard explicit:

- live executor completion without coordinator remediation
- implementation, tests, and documentation slices all required
- no production, secrets, billing, authentication, authorization, database, dependency installation, CI/CD security change, or deployment expansion

## Context

The first V5 live pilot completed, but the CLI implementation slice failed twice and required coordinator remediation. Issue 078 then added `v5-live-status` and bounded redacted runtime execution diagnostics.

This issue must use that improved evidence chain to run a stricter live pilot. The coordinator may define the contract, scope, handoff, launch plans, runtime records, summaries, metrics, final report, audit packet, and ChatGPT/Codex audit. The coordinator must not author product remediation in `scripts/specbridge.ps1`, `scripts/test-specbridge-cli.ps1`, `README.md`, or `docs/specbridge-v5-autonomy-status.md` after live execution begins.

## Source References

- README.md
- SPECBRIDGE.md
- AGENTS.md
- CLAUDE.md
- .specbridge/policy.yaml
- .specbridge/context/CURRENT_GOAL.md
- .specbridge/contracts/issue-076-v5-live-parallel-pilot.execution.md
- .specbridge/contracts/issue-078-v5-live-status-diagnostics.execution.md
- .specbridge/reports/issue-078-v5-live-status-diagnostics.final-report.json
- docs/specbridge-v5-live-status.md
- docs/specbridge-runtime-runner.md
- scripts/specbridge.ps1
- scripts/test-specbridge-cli.ps1
- scripts/validate-runtime-executions.ps1
- https://github.com/yagooyarzabaldev-ops/specbridge/issues/80

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
medium
```

Reason:

- this task changes local CLI behavior and tests
- it runs live Claude Code through bounded runtime launch plans
- it adds runtime evidence used by future autonomy decisions
- it does not modify production, secrets, billing, authentication, authorization, database, dependencies, deployment, or CI/CD security controls

## Allowed Scope

```text
.specbridge/audit-packets/issue-080-second-v5-live-autonomy-pilot.audit-packet.json
.specbridge/audits/issue-080-second-v5-live-autonomy-pilot.chatgpt-audit.json
.specbridge/context/CURRENT_GOAL.md
.specbridge/contracts/issue-080-second-v5-live-autonomy-pilot.execution.md
.specbridge/executor-handoffs/issue-080-second-v5-live-autonomy-pilot.input.json
.specbridge/executor-packets/issue-080-second-v5-live-autonomy-pilot-docs.executor-packet.json
.specbridge/executor-packets/issue-080-second-v5-live-autonomy-pilot-implementation.executor-packet.json
.specbridge/executor-packets/issue-080-second-v5-live-autonomy-pilot-tests.executor-packet.json
.specbridge/metrics/issue-080-second-v5-live-autonomy-pilot.autonomy-metrics.json
.specbridge/reports/issue-080-second-v5-live-autonomy-pilot.final-report.json
.specbridge/runtime-evidence/issue-080-docs.executor-output.md
.specbridge/runtime-evidence/issue-080-implementation.executor-output.md
.specbridge/runtime-evidence/issue-080-tests.executor-output.md
.specbridge/runtime-executions/issue-080-docs.runtime-execution.json
.specbridge/runtime-executions/issue-080-docs-retry-1.runtime-execution.json
.specbridge/runtime-executions/issue-080-implementation.runtime-execution.json
.specbridge/runtime-executions/issue-080-implementation-retry-1.runtime-execution.json
.specbridge/runtime-executions/issue-080-tests.runtime-execution.json
.specbridge/runtime-executions/issue-080-tests-retry-1.runtime-execution.json
.specbridge/runtime-launches/issue-080-docs.runtime-launch.json
.specbridge/runtime-launches/issue-080-implementation.runtime-launch.json
.specbridge/runtime-launches/issue-080-tests.runtime-launch.json
.specbridge/runtime-results/issue-080-docs.runtime-result.json
.specbridge/runtime-results/issue-080-implementation.runtime-result.json
.specbridge/runtime-results/issue-080-tests.runtime-result.json
.specbridge/runtime-runs/issue-080-docs.runtime-run.json
.specbridge/runtime-runs/issue-080-implementation.runtime-run.json
.specbridge/runtime-runs/issue-080-tests.runtime-run.json
.specbridge/runtime-summaries/issue-080-docs.runtime-summary.json
.specbridge/runtime-summaries/issue-080-implementation.runtime-summary.json
.specbridge/runtime-summaries/issue-080-tests.runtime-summary.json
.specbridge/scopes/issue-078-v5-live-status-diagnostics.scope.json
.specbridge/scopes/issue-080-second-v5-live-autonomy-pilot.scope.json
README.md
docs/specbridge-test-results.md
docs/specbridge-v5-autonomy-status.md
scripts/specbridge.ps1
scripts/test-specbridge-cli.ps1
GitHub issue 80
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
coordinator-authored product remediation after live execution starts
```

## Acceptance Criteria

- Issue 078 scope is marked `completed` so it no longer blocks issue 080.
- `CURRENT_GOAL.md` identifies issue 080 as the active work.
- `runtime-capability-status` reports `ok: true` before live execution starts.
- `v5-live-status` reports `ok: true` and `readiness_status: ready_for_second_live_pilot` before live execution starts.
- At least three executor packets are generated from `.specbridge/executor-handoffs/issue-080-second-v5-live-autonomy-pilot.input.json`.
- At least three runtime launch plans are generated.
- The implementation live executor writes `scripts/specbridge.ps1` and `.specbridge/runtime-evidence/issue-080-implementation.executor-output.md`.
- The tests live executor writes `scripts/test-specbridge-cli.ps1` and `.specbridge/runtime-evidence/issue-080-tests.executor-output.md`.
- The docs live executor writes `README.md`, `docs/specbridge-v5-autonomy-status.md`, and `.specbridge/runtime-evidence/issue-080-docs.executor-output.md`.
- `v5-autonomy-status` exists in `scripts/specbridge.ps1`.
- `v5-autonomy-status` reports `command`, `ok`, `branch`, `head`, `autonomy_standard`, `prior_live_pilot_status`, `target_live_pilot_status`, `required_slices`, `coordinator_remediation_allowed`, and `policy_boundary`.
- CLI tests cover `v5-autonomy-status`.
- Documentation explains `v5-autonomy-status`, required slices, policy boundary, and the no-coordinator-remediation target.
- Every product slice has a successful live `execute-runtime-launch -Force` artifact.
- `failure_diagnostics` is present in new runtime execution artifacts.
- No product file change is coordinator-authored after live execution starts.
- At most one live retry is allowed per slice, and any retry must be a live executor retry rather than coordinator remediation.
- Runtime-run, runtime-result, runtime-summary, and autonomy metrics artifacts are recorded after execution.
- Every runtime summary reaches `ready_for_policy_gates`.
- Autonomy metrics report `summary_count: 3`, `ready_count: 3`, `blocked_count: 0`, and `policy_gate_ready_rate: 1`.
- Local validations pass for contracts, scopes, executor packets, runtime launches, runtime executions, runtime runs, runtime results, runtime summaries, autonomy metrics, final reports, audit packets, ChatGPT audits, CLI tests, negative validations, smoke, security gate, review gate, standard profile, and git diff whitespace.
- GitHub CI and deterministic review gates pass before merge.
- No secrets, production configuration, billing, auth security, dependency installation, database changes, CI/CD weakening, or deployment automation are involved.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 runtime-capability-status
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 v5-live-status
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 v5-autonomy-status
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contract-scopes.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-executor-packets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-launches.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-executions.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-runs.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-results.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-summaries.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-autonomy-metrics.ps1
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

Execution must stop if the task requires workflow security changes, secrets, production configuration, billing, authentication or authorization security changes, dependency installation, database changes, deployment automation, protected file changes, coordinator-authored product remediation, repeated live executor failure, or scope outside the declared paths.

## Merge Policy

Gate-controlled automatic merge is allowed only after required local validations, GitHub CI, deterministic review report, security gate, review gate, audit packet validation, ChatGPT/Codex audit validation, scope validation, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

The final report must include summary, changed files, validations, live Claude Code execution evidence, no-remediation evidence, runtime evidence, autonomy metrics, policy result, risk result, merge status, deployment status, unresolved risks, and rollback notes if applicable.

## Completion Rule

This task is complete only when the live implementation, tests, and documentation slices complete without coordinator remediation, all evidence artifacts validate, GitHub CI passes, and policy-gated merge succeeds.
