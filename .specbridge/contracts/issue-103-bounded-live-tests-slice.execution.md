# Execution Contract: Issue 103 Bounded Live Tests Slice

## Contract Metadata

- contract_id: issue-103-bounded-live-tests-slice
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/103
- created_by: ChatGPT/Codex
- created_at: 2026-06-05
- autonomy_profile: full_autopilot
- risk_level: medium
- status: completed

## Goal

Run the second post-preflight bounded live slice from the prepared issue 097 multi-slice launch plans.

This contract authorizes exactly one live Claude Code execution through `execute-runtime-launch -Force`, limited to the prepared issue 097 `tests` runtime launch plan.

## Context

Issue 097 prepared three plan-only runtime launch artifacts: `status`, `tests`, and `docs`.

Issue 099 added and merged the deterministic runtime launch preflight command. That preflight confirms required slices, non-overlap, budget ceiling, tool allow-list, and plan-only execution policy before live launch consideration.

Issue 101 executed the prepared `docs` slice successfully, recorded bounded runtime evidence, and merged through PR 102.

The next governed step is to run one additional low-risk live slice. The `tests` slice is selected because its exclusive write scope is limited to the CLI test script and one executor evidence file. The `status` slice remains unlaunched by this contract.

## Source References

- README.md
- SPECBRIDGE.md
- AGENTS.md
- CLAUDE.md
- .specbridge/policy.yaml
- .specbridge/autonomy.yaml
- .specbridge/risk-rules.yaml
- .specbridge/context/CURRENT_GOAL.md
- .specbridge/preflights/issue-099-runtime-launch-preflight.runtime-preflight.json
- .specbridge/runtime-launches/issue-097-docs.runtime-launch.json
- .specbridge/runtime-launches/issue-097-status.runtime-launch.json
- .specbridge/runtime-launches/issue-097-tests.runtime-launch.json
- .specbridge/executor-packets/issue-097-multi-slice-live-pilot-contract-tests.executor-packet.json
- .specbridge/contracts/issue-097-multi-slice-live-pilot-contract.execution.md
- .specbridge/reports/issue-101-bounded-live-docs-slice.final-report.json
- docs/specbridge-runtime-launch-preflight.md
- docs/specbridge-runtime-runner.md
- docs/specbridge-runtime-capability-status.md
- https://github.com/yagooyarzabaldev-ops/specbridge/issues/103

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
medium
```

Reason:

- this task authorizes one bounded live Claude Code CLI execution
- the live executor is constrained by an already prepared and preflighted tests launch plan
- the executor write scope is limited to test coverage and executor evidence
- coordinator evidence is deterministic and repository-local

## Allowed Scope

```text
README.md
docs/specbridge-multi-slice-live-pilot-contract.md
scripts/test-specbridge-cli.ps1
.specbridge/audit-packets/issue-103-bounded-live-tests-slice.audit-packet.json
.specbridge/audits/issue-103-bounded-live-tests-slice.chatgpt-audit.json
.specbridge/context/CURRENT_GOAL.md
.specbridge/contracts/issue-103-bounded-live-tests-slice.execution.md
.specbridge/preflights/issue-103-bounded-live-tests-slice.runtime-preflight.json
.specbridge/reports/issue-103-bounded-live-tests-slice.final-report.json
.specbridge/runtime-evidence/issue-097-tests.executor-output.md
.specbridge/runtime-executions/issue-103-tests.runtime-execution.json
.specbridge/runtime-results/issue-103-tests.runtime-result.json
.specbridge/runtime-runs/issue-103-tests.runtime-run.json
.specbridge/runtime-summaries/issue-103-tests.runtime-summary.json
.specbridge/scopes/issue-103-bounded-live-tests-slice.scope.json
.specbridge/standard-loop-runs/issue-103-bounded-live-tests-slice.standard-loop-run.json
GitHub issue 103
GitHub pull request for this branch
```

## Live Executor Exclusive Write Scope

The live Claude Code executor must modify only:

```text
scripts/test-specbridge-cli.ps1
.specbridge/runtime-evidence/issue-097-tests.executor-output.md
```

The coordinator may write the issue 103 evidence artifacts listed in allowed scope.

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
live status slice launch
live docs slice launch
unprepared runtime launch plans
deployment automation
production deployment
```

## Acceptance Criteria

- `runtime-capability-status` reports `ok=true` before live execution.
- `preflight-runtime-launches` passes for the prepared issue 097 `status`, `tests`, and `docs` launch plans before live execution.
- Exactly one live `execute-runtime-launch -Force` run is attempted, using `.specbridge/runtime-launches/issue-097-tests.runtime-launch.json`.
- No live `status` or `docs` slice is launched.
- Any executor-written files are limited to the tests launch plan exclusive write paths.
- Runtime execution, runtime-run, runtime result, and runtime summary artifacts exist.
- Runtime execution diagnostics are bounded and redacted; no unbounded stdout or stderr is committed.
- Runtime run, runtime result, runtime summary, preflight, contract, scope, final report, audit packet, and ChatGPT/Codex audit artifacts validate.
- `scripts/test-specbridge-cli.ps1` contains focused CLI coverage added by the live tests slice or a bounded failure records why no change was made.
- README and CURRENT_GOAL record the issue 103 repository memory closure.
- Local security gate, review gate, standard validation, smoke validation, CLI tests, and whitespace checks pass.
- GitHub CI passes before merge.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 runtime-capability-status
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 preflight-runtime-launches -InputPath ".specbridge/runtime-launches/issue-097-status.runtime-launch.json,.specbridge/runtime-launches/issue-097-tests.runtime-launch.json,.specbridge/runtime-launches/issue-097-docs.runtime-launch.json" -RequiredSlice status,tests,docs -AllowedTool Read,Write,Edit -MaxBudgetUsd 2.00 -OutputPath .specbridge/preflights/issue-103-bounded-live-tests-slice.runtime-preflight.json -Force
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 execute-runtime-launch -InputPath .specbridge/runtime-launches/issue-097-tests.runtime-launch.json -OutputPath .specbridge/runtime-executions/issue-103-tests.runtime-execution.json -TimeoutSeconds 900 -Force
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 run-runtime-launch -InputPath .specbridge/runtime-launches/issue-097-tests.runtime-launch.json -EvidencePath .specbridge/runtime-evidence/issue-097-tests.executor-output.md -OutputPath .specbridge/runtime-runs/issue-103-tests.runtime-run.json -RuntimeExitCode 0 -WrittenFile scripts/test-specbridge-cli.ps1 -WrittenFile .specbridge/runtime-evidence/issue-097-tests.executor-output.md -Validation "execute-runtime-launch tests: passed" -Validation "test-specbridge-cli: passed" -Validation "validate-standard: passed" -PolicyResult "Passed. Live tests executor completed inside the issue 097 tests launch scope under issue 103 coordinator review." -CompletionStatus complete
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 record-runtime-result -InputPath .specbridge/runtime-launches/issue-097-tests.runtime-launch.json -EvidencePath .specbridge/runtime-evidence/issue-097-tests.executor-output.md -OutputPath .specbridge/runtime-results/issue-103-tests.runtime-result.json -RuntimeExitCode 0 -WrittenFile scripts/test-specbridge-cli.ps1 -WrittenFile .specbridge/runtime-evidence/issue-097-tests.executor-output.md -Validation "execute-runtime-launch tests: passed" -Validation "test-specbridge-cli: passed" -Validation "validate-standard: passed" -PolicyResult "Passed. Live tests executor completed inside the issue 097 tests launch scope under issue 103 coordinator review." -CompletionStatus complete
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 summarize-runtime -InputPath .specbridge/runtime-launches/issue-097-tests.runtime-launch.json -EvidencePath .specbridge/runtime-results/issue-103-tests.runtime-result.json -OutputPath .specbridge/runtime-summaries/issue-103-tests.runtime-summary.json -Force
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 standard-loop-orchestrate -TaskId issue-103-bounded-live-tests-slice -OutputPath .specbridge/standard-loop-runs/issue-103-bounded-live-tests-slice.standard-loop-run.json -Force
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 validate -Profile standard
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/test-specbridge-cli.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-executions.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-runs.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-results.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-summaries.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-preflights.ps1
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

Stop if the task requires secrets, production configuration, billing, authentication security, authorization security, dependency installation, database changes, CI/CD security changes, unprepared runtime launches, live `status` or `docs` slice launch, deployment automation, or scope outside the declared paths.

Stop if the tests executor writes outside the two live executor exclusive write paths.

## Merge Policy

Autonomous merge is allowed only after required local validations, GitHub CI, security gate, review gate, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

The final report must include summary, changed files, validations, policy result, risk result, review result, merge status, deployment status, unresolved risks, rollback notes, and completion status.

## Completion Rule

This task is complete when the live tests slice is executed or bounded failure is recorded, all issue 103 evidence artifacts validate, local gates pass, GitHub CI passes, and the branch is policy-gated into main.
