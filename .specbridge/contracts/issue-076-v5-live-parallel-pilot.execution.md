# Execution Contract: Issue 76 V5 Live Parallel Pilot

## Contract Metadata

- contract_id: issue-076-v5-live-parallel-pilot
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/76
- created_by: ChatGPT/Codex
- created_at: 2026-06-03
- autonomy_profile: full_autopilot
- risk_level: medium
- status: ready_for_execution

## Goal

Run the first V5 live parallel pilot after `v5-pilot-status` readiness passed.

The pilot implements one small product behavior change: `runtime-capability-status`, a local CLI command that reports whether the Claude Code CLI and Antigravity application are discoverable before live runtime work starts.

The pilot must use multiple bounded executor slices, non-overlapping write scopes, controlled runtime launch evidence, runtime-run/result/summary artifacts, autonomy metrics, final report, audit packet, ChatGPT/Codex audit, GitHub CI, and policy-gated merge.

## Context

V5 readiness is complete on `main` and `v5-pilot-status` reports `ok: true`.

This contract authorizes a controlled live Claude Code executor pilot from the Antigravity workspace path. Antigravity availability is verified through the local application path, but the standard runner launches Claude Code non-interactively through `execute-runtime-launch`. This distinction must be recorded honestly in runtime evidence and final reporting.

If a live executor slice fails twice, no further live attempts are allowed for that slice. The coordinator may complete the scoped product change manually only when the final report records the repeated live failure, the remediation path, and the remaining autonomy risk.

## Source References

- README.md
- SPECBRIDGE.md
- AGENTS.md
- CLAUDE.md
- .specbridge/policy.yaml
- .specbridge/context/CURRENT_GOAL.md
- .specbridge/contracts/v5-pilot-readiness.execution.md
- docs/specbridge-v5-live-parallel-pilot-boundary.md
- docs/specbridge-standard-loop-v1.md
- docs/specbridge-runtime-runner.md
- scripts/specbridge.ps1
- scripts/test-specbridge-cli.ps1
- https://github.com/yagooyarzabaldev-ops/specbridge/issues/76

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
- it runs live Claude Code through bounded launch plans
- it adds live runtime evidence used by future autonomous execution
- it does not modify CI/CD workflow security controls, production, secrets, auth, billing, database, dependencies, or deployment

## Allowed Scope

```text
.specbridge/audit-packets/issue-076-v5-live-parallel-pilot.audit-packet.json
.specbridge/audits/issue-076-v5-live-parallel-pilot.chatgpt-audit.json
.specbridge/context/CURRENT_GOAL.md
.specbridge/contracts/issue-076-v5-live-parallel-pilot.execution.md
.specbridge/executor-handoffs/issue-076-v5-live-parallel-pilot.input.json
.specbridge/executor-packets/issue-076-v5-live-parallel-pilot-cli-capability.executor-packet.json
.specbridge/executor-packets/issue-076-v5-live-parallel-pilot-docs-capability.executor-packet.json
.specbridge/executor-packets/issue-076-v5-live-parallel-pilot-tests-capability.executor-packet.json
.specbridge/metrics/issue-076-v5-live-parallel-pilot.autonomy-metrics.json
.specbridge/reports/issue-076-v5-live-parallel-pilot.final-report.json
.specbridge/runtime-evidence/issue-076-cli-capability.executor-output.md
.specbridge/runtime-evidence/issue-076-docs-capability.executor-output.md
.specbridge/runtime-evidence/issue-076-tests-capability.executor-output.md
.specbridge/runtime-executions/issue-076-cli-capability.runtime-execution.json
.specbridge/runtime-executions/issue-076-cli-capability-retry-1.runtime-execution.json
.specbridge/runtime-executions/issue-076-docs-capability.runtime-execution.json
.specbridge/runtime-executions/issue-076-tests-capability.runtime-execution.json
.specbridge/runtime-launches/issue-076-cli-capability.runtime-launch.json
.specbridge/runtime-launches/issue-076-docs-capability.runtime-launch.json
.specbridge/runtime-launches/issue-076-tests-capability.runtime-launch.json
.specbridge/runtime-results/issue-076-cli-capability.runtime-result.json
.specbridge/runtime-results/issue-076-docs-capability.runtime-result.json
.specbridge/runtime-results/issue-076-tests-capability.runtime-result.json
.specbridge/runtime-runs/issue-076-cli-capability.runtime-run.json
.specbridge/runtime-runs/issue-076-docs-capability.runtime-run.json
.specbridge/runtime-runs/issue-076-tests-capability.runtime-run.json
.specbridge/runtime-summaries/issue-076-cli-capability.runtime-summary.json
.specbridge/runtime-summaries/issue-076-docs-capability.runtime-summary.json
.specbridge/runtime-summaries/issue-076-tests-capability.runtime-summary.json
.specbridge/scopes/issue-076-v5-live-parallel-pilot.scope.json
README.md
docs/specbridge-runtime-capability-status.md
docs/specbridge-test-results.md
scripts/specbridge.ps1
scripts/test-specbridge-cli.ps1
GitHub issue 76
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

- `v5-pilot-status` reports `ok: true` before live execution starts.
- Antigravity application availability is verified and recorded without requiring production, secrets, billing, auth, database, CI/CD security, dependency installation, or deployment access.
- `runtime-capability-status` exists in `scripts/specbridge.ps1`.
- `runtime-capability-status` reports `command`, `ok`, `branch`, `head`, `claude.available`, `claude.path`, `claude.version`, `antigravity.available`, `antigravity.path`, and a policy boundary that confirms no launch/deploy/secret access.
- CLI tests cover `runtime-capability-status`.
- Documentation explains the command and distinguishes Antigravity availability from live runner execution.
- At least three executor packets are generated from the handoff input.
- At least three runtime launch plans are generated.
- At least three live `execute-runtime-launch -Force` executions are attempted with bounded tools, budget, and timeout.
- Any live retry required after a failed executor attempt is recorded as a separate runtime execution artifact.
- Any coordinator remediation after repeated live executor failure is recorded separately from live execution success.
- Every successful live executor writes only its declared exclusive evidence file and assigned source path.
- Runtime-run, runtime-result, runtime-summary, and autonomy metrics artifacts are recorded after execution.
- Every completed runtime summary reaches `ready_for_policy_gates`.
- Local validations pass for contracts, scopes, executor packets, runtime launches, runtime executions, runtime runs, runtime results, runtime summaries, autonomy metrics, final reports, audit packets, ChatGPT audits, CLI tests, standard profile, smoke, security gate, review gate, and git diff whitespace.
- GitHub CI and deterministic review gates pass before merge.
- No secrets, production configuration, billing, auth security, dependency installation, database changes, CI/CD weakening, or deployment automation are involved.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 v5-pilot-status
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 runtime-capability-status
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

Execution must stop if the task requires workflow security changes, secrets, production configuration, billing, authentication or authorization security changes, dependency installation, database changes, deployment automation, protected file changes, repeated live executor failure, or scope outside the declared paths.

## Merge Policy

Gate-controlled automatic merge is allowed only after required local validations, GitHub CI, deterministic review report, security gate, review gate, audit packet validation, ChatGPT/Codex audit validation, scope validation, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

The final report must include summary, changed files, validations, live Claude Code execution evidence, Antigravity availability evidence, runtime evidence, autonomy metrics, policy result, risk result, merge status, deployment status, unresolved risks, and rollback notes if applicable.

## Completion Rule

This task is complete only when the live pilot artifacts, feature change, tests, docs, runtime evidence, final report, audit packet, ChatGPT/Codex audit, local validations, GitHub CI, and policy-gated merge have passed or when a policy stop condition is recorded honestly.
