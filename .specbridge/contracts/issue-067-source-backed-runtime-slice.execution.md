# Execution Contract: Issue 67 Source-Backed Runtime Slice

## Contract Metadata

- contract_id: issue-067-source-backed-runtime-slice
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/67
- created_by: ChatGPT/Codex
- created_at: 2026-05-21
- autonomy_profile: full_autopilot
- risk_level: medium
- status: ready_for_execution

## Goal

Prove the first source-backed SpecBridge runtime implementation slice by adding one small CLI feature that reads a declared runtime launch plan and runtime result, then writes a validated runtime summary artifact.

## Context

Issue 063 added runtime launch plans and issue 065 added runtime result recording. The next product proof must use both evidence layers against a real source change rather than another documentation-only milestone.

This task authorizes a bounded CLI implementation slice named `summarize-runtime`. The command must read one `.specbridge/runtime-launches/*.runtime-launch.json` artifact and one `.specbridge/runtime-results/*.runtime-result.json` artifact, verify that they describe the same launch/result chain, and write one `.specbridge/runtime-summaries/*.runtime-summary.json` artifact.

The command is source-backed because it changes the local SpecBridge CLI implementation and tests. It remains evidence-only and must not launch Claude Code, Antigravity, shell commands, GitHub operations, dependency installation, deployment, or any production surface.

## Source References

- README.md
- SPECBRIDGE.md
- AGENTS.md
- CLAUDE.md
- .specbridge/policy.yaml
- docs/specbridge-autonomy-backlog.md
- docs/specbridge-runtime-launch-plans.md
- docs/specbridge-runtime-results.md
- .specbridge/runtime-launches/issue-063-prepare-runtime-launch-plans.runtime-launch.json
- .specbridge/runtime-results/issue-065-record-runtime-results.runtime-result.json
- https://github.com/yagooyarzabaldev-ops/specbridge/issues/67

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
medium
```

Reason:

- this task adds a new source-backed CLI behavior and runtime evidence artifact type
- summaries may be used by later runtime gates and audit flows
- no live executor launch, dependency installation, secrets, production configuration, billing, auth security, database, CI/CD security weakening, deployment, MCP server, GitHub App, or hosted dashboard implementation is authorized

## Allowed Scope

```text
.specbridge/contracts/issue-067-source-backed-runtime-slice.execution.md
.specbridge/scopes/issue-067-source-backed-runtime-slice.scope.json
.specbridge/runtime-summaries/issue-067-source-backed-runtime-slice.runtime-summary.json
.specbridge/reports/issue-067-source-backed-runtime-slice.final-report.json
.specbridge/audit-packets/issue-067-source-backed-runtime-slice.audit-packet.json
.specbridge/audits/issue-067-source-backed-runtime-slice.chatgpt-audit.json
.specbridge/context/CURRENT_GOAL.md
.specbridge/context/ACCEPTANCE_CRITERIA.md
scripts/specbridge.ps1
scripts/test-specbridge-cli.ps1
scripts/test-specbridge-negative-validations.ps1
scripts/specbridge-smoke.ps1
scripts/validate-runtime-summaries.ps1
docs/specbridge-runtime-summaries.md
docs/specbridge-runtime-results.md
docs/specbridge-runtime-launch-plans.md
docs/specbridge-local-cli.md
docs/specbridge-autonomy-backlog.md
docs/specbridge-test-results.md
README.md
specs/004-acceptance-tests.md
GitHub issue 67
GitHub pull request for this branch
```

## Blocked Scope

```text
.env
.env.*
secrets/**
infra/prod/**
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
raw file content capture
production deployment
destructive infrastructure operation
unrestricted shell execution
live Claude Code process launch by the new command
live Antigravity session launch by the new command
```

## Acceptance Criteria

- `scripts/specbridge.ps1` exposes `summarize-runtime`.
- The command reads exactly one declared `.specbridge/runtime-launches/*.runtime-launch.json` input file.
- The command reads exactly one declared `.specbridge/runtime-results/*.runtime-result.json` evidence file.
- The command writes only one declared `.specbridge/runtime-summaries/*.runtime-summary.json` output file.
- The runtime summary artifact records schema version, summary id, launch path, result path, launch id, task id, packet id, slice id, branch name, completion status, runtime status, result status, validation totals, policy result, merge readiness, blockers, execution policy, and source files.
- The command rejects launch/result mismatches for launch id, task id, packet id, slice id, branch name, and source runtime launch path.
- The command does not launch Claude Code, Antigravity, shell commands, package managers, GitHub operations, deployments, or network calls.
- `scripts/validate-runtime-summaries.ps1` validates runtime summary artifacts.
- `scripts/specbridge.ps1 validate -Profile standard` includes runtime summary validation.
- `scripts/specbridge-smoke.ps1` includes runtime summary validation.
- `scripts/test-specbridge-cli.ps1` covers successful runtime summary generation and deterministic mismatch failure.
- `scripts/test-specbridge-negative-validations.ps1` covers invalid runtime summary artifacts.
- Repository memory identifies source-backed runtime summary as complete and the next remaining runtime expansion clearly.
- No secrets, production configuration, billing, auth security, dependency installation, database changes, CI/CD weakening, live launch expansion, or deployment automation are involved.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-summaries.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-results.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/test-specbridge-cli.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/test-specbridge-negative-validations.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contract-scopes.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 validate -Profile standard
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-audit-packets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-chatgpt-audits.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-security-gates.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-review-gate.ps1
git diff --check
```

## Stop Conditions

Execution must stop if the task requires secrets, production configuration, billing, authentication or authorization security changes, dependency installation, database changes, CI/CD security changes, deployment automation, live Claude Code launch by the new command, live Antigravity launch by the new command, unrestricted shell execution, protected file changes, or scope outside the declared paths.

## Merge Policy

Gate-controlled automatic merge is allowed only after required gates pass.

Autonomous merge must not bypass CI, validation, policy checks, review gates, security gate validation, audit packet validation, ChatGPT audit validation, runtime result validation, runtime summary validation, or scope validation.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

The final report must include summary, changed files, validations, runtime summary evidence, policy result, risk result, merge status, deployment status, unresolved risks, and rollback notes if applicable.

## Completion Rule

This task is complete only when the CLI command, validator, tests, documentation, runtime summary artifact, final report, audit packet, ChatGPT/Codex audit, local validations, GitHub CI, and policy-gated merge have passed.
