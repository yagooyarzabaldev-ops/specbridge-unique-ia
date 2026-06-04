# Execution Contract: Issue 87 Budget-Aware V5 Serious Status

## Contract Metadata

- contract_id: issue-087-budget-aware-v5-status
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/87
- created_by: ChatGPT/Codex
- created_at: 2026-06-04
- autonomy_profile: full_autopilot
- risk_level: medium
- status: completed

## Goal

Complete the V5 serious pilot status work after issue 086 blocked, while fixing the timeout evidence bug discovered by that pilot.

The task has two ordered phases:

1. Coordinator fixes the runtime runner timeout artifact so a killed Claude process records a schema-valid exit code.
2. Live Claude Code slices implement, test, and document `v5-serious-pilot-status` with budget-aware launch plans that allow `Edit`, `Read`, and `Write`.

## Context

Issue 086 blocked before product implementation. The implementation slice timed out once and then exceeded the required `2.00` USD budget on the single allowed retry. It also exposed that a timed-out runtime execution artifact can record `exit_code: -1`, which is outside the current runtime-execution validator range.

Issue 080 used `Edit,Read,Write` for a comparable status-command live slice and completed within the hardened `2.00` USD budget. Issue 087 uses that proven tool baseline and smaller goals.

## Source References

- README.md
- SPECBRIDGE.md
- AGENTS.md
- CLAUDE.md
- .specbridge/policy.yaml
- .specbridge/context/CURRENT_GOAL.md
- .specbridge/contracts/issue-086-serious-v5-live-pilot.execution.md
- .specbridge/reports/issue-086-serious-v5-live-pilot.final-report.json
- docs/specbridge-v5-autonomy-status.md
- docs/specbridge-runtime-runner.md
- scripts/specbridge.ps1
- scripts/test-specbridge-cli.ps1
- https://github.com/yagooyarzabaldev-ops/specbridge/issues/87

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
medium
```

Reason:

- this task changes local CLI behavior, tests, README, docs, and runtime evidence behavior
- it uses live Claude Code for product status, tests, and docs after the runner timeout fix
- it does not modify production, secrets, billing, authentication, authorization, database, dependencies, deployment, or CI/CD security controls

## Allowed Scope

```text
.specbridge/audit-packets/issue-087-budget-aware-v5-status.audit-packet.json
.specbridge/audits/issue-087-budget-aware-v5-status.chatgpt-audit.json
.specbridge/context/CURRENT_GOAL.md
.specbridge/contracts/issue-087-budget-aware-v5-status.execution.md
.specbridge/executor-handoffs/issue-087-budget-aware-v5-status.input.json
.specbridge/executor-packets/issue-087-budget-aware-v5-status-docs.executor-packet.json
.specbridge/executor-packets/issue-087-budget-aware-v5-status-status.executor-packet.json
.specbridge/executor-packets/issue-087-budget-aware-v5-status-tests.executor-packet.json
.specbridge/metrics/issue-087-budget-aware-v5-status.autonomy-metrics.json
.specbridge/reports/issue-087-budget-aware-v5-status.final-report.json
.specbridge/runtime-evidence/issue-087-docs.executor-output.md
.specbridge/runtime-evidence/issue-087-status.executor-output.md
.specbridge/runtime-evidence/issue-087-tests.executor-output.md
.specbridge/runtime-executions/issue-087-docs.runtime-execution.json
.specbridge/runtime-executions/issue-087-docs-retry-1.runtime-execution.json
.specbridge/runtime-executions/issue-087-status.runtime-execution.json
.specbridge/runtime-executions/issue-087-status-retry-1.runtime-execution.json
.specbridge/runtime-executions/issue-087-tests.runtime-execution.json
.specbridge/runtime-executions/issue-087-tests-retry-1.runtime-execution.json
.specbridge/runtime-launches/issue-087-docs.runtime-launch.json
.specbridge/runtime-launches/issue-087-status.runtime-launch.json
.specbridge/runtime-launches/issue-087-tests.runtime-launch.json
.specbridge/runtime-results/issue-087-docs.runtime-result.json
.specbridge/runtime-results/issue-087-status.runtime-result.json
.specbridge/runtime-results/issue-087-tests.runtime-result.json
.specbridge/runtime-runs/issue-087-docs.runtime-run.json
.specbridge/runtime-runs/issue-087-status.runtime-run.json
.specbridge/runtime-runs/issue-087-tests.runtime-run.json
.specbridge/runtime-summaries/issue-087-docs.runtime-summary.json
.specbridge/runtime-summaries/issue-087-status.runtime-summary.json
.specbridge/runtime-summaries/issue-087-tests.runtime-summary.json
.specbridge/scopes/issue-087-budget-aware-v5-status.scope.json
README.md
docs/specbridge-runtime-runner.md
docs/specbridge-v5-serious-pilot-status.md
scripts/specbridge.ps1
scripts/test-specbridge-cli.ps1
GitHub issue 87
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
coordinator-authored remediation of live status/tests/docs slices after those live slices start
```

## Acceptance Criteria

- `execute-runtime-launch` timeout artifacts use a validator-compatible exit code when the child process is killed.
- CLI tests cover timeout exit-code normalization.
- Three runtime launch plans are generated for `status`, `tests`, and `docs` and use `allowed_tools: ["Edit","Read","Write"]` and `max_budget_usd: "2.00"`.
- `v5-serious-pilot-status` exists in `scripts/specbridge.ps1`.
- `v5-serious-pilot-status` returns JSON with `command`, `ok`, `branch`, `head`, `pilot_standard`, `runner_baseline`, `required_slices`, `default_runtime_budget_usd`, `diagnostic_preview_policy`, `target_completion_status`, `coordinator_remediation_allowed`, and `policy_boundary`.
- The command reports `pilot_standard: serious_live_multi_slice_no_remediation`.
- The command reports `runner_baseline: v5_hardened_runtime_runner`.
- The command reports `required_slices: ["status","tests","docs"]`.
- The command reports `default_runtime_budget_usd: "2.00"`.
- The command reports `diagnostic_preview_policy: ascii_stable_bounded_240_chars`.
- The command reports `target_completion_status: completed_without_coordinator_remediation`.
- The command reports `coordinator_remediation_allowed: false`.
- CLI tests cover `v5-serious-pilot-status`.
- Documentation explains `v5-serious-pilot-status`, hardened runner baseline, required slices, timeout artifact normalization, no-remediation target, and policy boundary.
- Runtime-run, runtime-result, runtime-summary, autonomy metrics, final report, audit packet, and ChatGPT audit artifacts are recorded.
- Every completed live slice has a successful `execute-runtime-launch -Force` artifact or a blocked artifact with no coordinator product remediation.
- Local validations pass for contracts, scopes, executor packets, runtime launches, runtime executions, runtime runs, runtime results, runtime summaries, autonomy metrics, final reports, audit packets, ChatGPT audits, CLI tests, negative validations, smoke, security gate, review gate, standard profile, and git diff whitespace.
- GitHub CI and deterministic review gates pass before merge.
- No secrets, production configuration, billing, auth security, dependency installation, database changes, CI/CD weakening, or deployment automation are involved.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 runtime-capability-status
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 v5-serious-pilot-status
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

- policy conflict
- scope conflict
- missing required context
- impossible acceptance criteria
- protected resource requirement
- secrets, production, billing, authentication, authorization, database, dependency installation, CI/CD security, or deployment requirement
- live slice fails twice under the active budget

## Merge Policy

Merge is allowed only after local validations, GitHub CI, security gate, review gate, audit packet, and ChatGPT audit pass.

## Deployment Policy

No deployment is allowed or required.

## Final Report Requirements

The final report must include summary, changed files, validations, policy result, risk result, merge status, deployment status, unresolved risks, and completion status.

## Completion Rule

The task is complete only when the timeout runner fix is validated, `v5-serious-pilot-status` is implemented and tested, documentation is updated, runtime and audit evidence is recorded, and the branch is merged under policy gates.
