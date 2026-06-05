# Execution Contract: Issue 101 Bounded Live Docs Slice

## Contract Metadata

- contract_id: issue-101-bounded-live-docs-slice
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/101
- created_by: ChatGPT/Codex
- created_at: 2026-06-05
- autonomy_profile: full_autopilot
- risk_level: medium
- status: completed

## Goal

Run the first post-preflight bounded live slice from the prepared issue 097 multi-slice launch plans.

This contract authorizes exactly one live Claude Code execution through `execute-runtime-launch -Force`, limited to the prepared issue 097 `docs` runtime launch plan.

## Context

Issue 097 prepared three plan-only runtime launch artifacts: `status`, `tests`, and `docs`.

Issue 099 added and merged the deterministic runtime launch preflight command. That preflight confirms required slices, non-overlap, budget ceiling, tool allow-list, and plan-only execution policy before live launch consideration.

The next governed step is to run one lowest-risk live slice. The `docs` slice is selected because its exclusive write scope is limited to one documentation file and one executor evidence file. The `status` and `tests` slices remain unlaunched by this contract.

## Source References

- README.md
- SPECBRIDGE.md
- AGENTS.md
- CLAUDE.md
- .specbridge/policy.yaml
- .specbridge/context/CURRENT_GOAL.md
- .specbridge/preflights/issue-099-runtime-launch-preflight.runtime-preflight.json
- .specbridge/runtime-launches/issue-097-docs.runtime-launch.json
- .specbridge/runtime-launches/issue-097-status.runtime-launch.json
- .specbridge/runtime-launches/issue-097-tests.runtime-launch.json
- .specbridge/contracts/issue-097-multi-slice-live-pilot-contract.execution.md
- docs/specbridge-runtime-launch-preflight.md
- docs/specbridge-runtime-runner.md
- docs/specbridge-runtime-capability-status.md
- https://github.com/yagooyarzabaldev-ops/specbridge/issues/101

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
- the live executor is constrained by an already prepared and preflighted docs launch plan
- the executor write scope is limited to documentation and executor evidence
- coordinator evidence is deterministic and repository-local

## Allowed Scope

```text
README.md
docs/specbridge-multi-slice-live-pilot-contract.md
.specbridge/audit-packets/issue-101-bounded-live-docs-slice.audit-packet.json
.specbridge/audits/issue-101-bounded-live-docs-slice.chatgpt-audit.json
.specbridge/context/CURRENT_GOAL.md
.specbridge/contracts/issue-101-bounded-live-docs-slice.execution.md
.specbridge/preflights/issue-101-bounded-live-docs-slice.runtime-preflight.json
.specbridge/reports/issue-101-bounded-live-docs-slice.final-report.json
.specbridge/runtime-evidence/issue-097-docs.executor-output.md
.specbridge/runtime-executions/issue-101-docs.runtime-execution.json
.specbridge/runtime-results/issue-101-docs.runtime-result.json
.specbridge/runtime-runs/issue-101-docs.runtime-run.json
.specbridge/runtime-summaries/issue-101-docs.runtime-summary.json
.specbridge/scopes/issue-101-bounded-live-docs-slice.scope.json
.specbridge/standard-loop-runs/issue-101-bounded-live-docs-slice.standard-loop-run.json
GitHub issue 101
GitHub pull request for this branch
```

## Live Executor Exclusive Write Scope

The live Claude Code executor must modify only:

```text
docs/specbridge-multi-slice-live-pilot-contract.md
.specbridge/runtime-evidence/issue-097-docs.executor-output.md
```

The coordinator may write the issue 101 evidence artifacts listed in allowed scope.

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
live tests slice launch
unprepared runtime launch plans
deployment automation
production deployment
```

## Acceptance Criteria

- `runtime-capability-status` reports `ok=true` before live execution.
- `preflight-runtime-launches` passes for the prepared issue 097 `status`, `tests`, and `docs` launch plans before live execution.
- Exactly one live `execute-runtime-launch -Force` run is attempted, using `.specbridge/runtime-launches/issue-097-docs.runtime-launch.json`.
- No live `status` or `tests` slice is launched.
- Any executor-written files are limited to the docs launch plan exclusive write paths.
- Runtime execution, runtime-run, runtime result, and runtime summary artifacts exist.
- Runtime execution diagnostics are bounded and redacted; no unbounded stdout or stderr is committed.
- Runtime run, runtime result, runtime summary, preflight, contract, scope, final report, audit packet, and ChatGPT/Codex audit artifacts validate.
- `docs/specbridge-multi-slice-live-pilot-contract.md` records the post-preflight live docs-slice outcome.
- README and CURRENT_GOAL record the issue 101 repository memory closure.
- Local security gate, review gate, standard validation, smoke validation, and whitespace checks pass.
- GitHub CI passes before merge.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 runtime-capability-status
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 preflight-runtime-launches -InputPath ".specbridge/runtime-launches/issue-097-status.runtime-launch.json,.specbridge/runtime-launches/issue-097-tests.runtime-launch.json,.specbridge/runtime-launches/issue-097-docs.runtime-launch.json" -RequiredSlice status,tests,docs -AllowedTool Read,Write,Edit -MaxBudgetUsd 2.00 -OutputPath .specbridge/preflights/issue-101-bounded-live-docs-slice.runtime-preflight.json -Force
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 execute-runtime-launch -InputPath .specbridge/runtime-launches/issue-097-docs.runtime-launch.json -OutputPath .specbridge/runtime-executions/issue-101-docs.runtime-execution.json -TimeoutSeconds 900 -Force
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 run-runtime-launch -InputPath .specbridge/runtime-launches/issue-097-docs.runtime-launch.json -EvidencePath .specbridge/runtime-evidence/issue-097-docs.executor-output.md -OutputPath .specbridge/runtime-runs/issue-101-docs.runtime-run.json -RuntimeExitCode 0 -WrittenFile docs/specbridge-multi-slice-live-pilot-contract.md -WrittenFile .specbridge/runtime-evidence/issue-097-docs.executor-output.md -Validation "execute-runtime-launch docs: passed" -Validation "validate-foundation: passed" -Validation "validate-contracts: passed" -PolicyResult "Passed. Live docs executor completed inside the issue 097 docs launch scope under issue 101 coordinator review." -CompletionStatus complete
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 record-runtime-result -InputPath .specbridge/runtime-launches/issue-097-docs.runtime-launch.json -EvidencePath .specbridge/runtime-evidence/issue-097-docs.executor-output.md -OutputPath .specbridge/runtime-results/issue-101-docs.runtime-result.json -RuntimeExitCode 0 -WrittenFile docs/specbridge-multi-slice-live-pilot-contract.md -WrittenFile .specbridge/runtime-evidence/issue-097-docs.executor-output.md -Validation "execute-runtime-launch docs: passed" -Validation "validate-foundation: passed" -Validation "validate-contracts: passed" -PolicyResult "Passed. Live docs executor completed inside the issue 097 docs launch scope under issue 101 coordinator review." -CompletionStatus complete
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 summarize-runtime -InputPath .specbridge/runtime-launches/issue-097-docs.runtime-launch.json -EvidencePath .specbridge/runtime-results/issue-101-docs.runtime-result.json -OutputPath .specbridge/runtime-summaries/issue-101-docs.runtime-summary.json -Force
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 standard-loop-orchestrate -TaskId issue-101-bounded-live-docs-slice -OutputPath .specbridge/standard-loop-runs/issue-101-bounded-live-docs-slice.standard-loop-run.json -Force
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 validate -Profile standard
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

Stop if the task requires secrets, production configuration, billing, authentication security, authorization security, dependency installation, database changes, CI/CD security changes, unprepared runtime launches, live `status` or `tests` slice launch, deployment automation, or scope outside the declared paths.

Stop if the docs executor writes outside the two live executor exclusive write paths.

## Merge Policy

Autonomous merge is allowed only after required local validations, GitHub CI, security gate, review gate, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

The final report must include summary, changed files, validations, policy result, risk result, review result, merge status, deployment status, unresolved risks, rollback notes, and completion status.

## Completion Rule

This task is complete when the live docs slice is executed or bounded failure is recorded, all issue 101 evidence artifacts validate, local gates pass, GitHub CI passes, and the branch is policy-gated into main.
