# Execution Contract: Issue 69 Fresh Executor Source Run

## Contract Metadata

- contract_id: issue-069-fresh-executor-source-run
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/69
- created_by: ChatGPT/Codex
- created_at: 2026-05-22
- autonomy_profile: full_autopilot
- risk_level: medium
- status: ready_for_execution

## Goal

Run one controlled fresh Claude Code executor source task, then record and summarize the result through SpecBridge runtime evidence layers.

## Context

Issue 063 added runtime launch plans. Issue 065 added runtime result recording. Issue 067 added runtime summaries. This task must prove that those layers can be used for fresh executor output generated after a dedicated source-backed runtime contract is declared.

The executor task is deliberately small: create one operational source document that records how fresh executor runs must be governed, plus one executor output evidence file. Claude Code must run non-interactively with bounded `Read` and `Write` tools only.

## Source References

- README.md
- SPECBRIDGE.md
- AGENTS.md
- CLAUDE.md
- .specbridge/policy.yaml
- docs/specbridge-autonomy-backlog.md
- docs/specbridge-runtime-launch-plans.md
- docs/specbridge-runtime-results.md
- docs/specbridge-runtime-summaries.md
- https://github.com/yagooyarzabaldev-ops/specbridge/issues/69

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
medium
```

Reason:

- this task launches Claude Code non-interactively for a bounded source-backed executor run
- the run is limited to two declared write paths and `Read`/`Write` tools
- no secrets, production configuration, billing, auth security, database change, dependency installation, CI/CD security weakening, deployment, MCP server, GitHub App, or hosted dashboard implementation is authorized

## Allowed Scope

```text
.specbridge/contracts/issue-069-fresh-executor-source-run.execution.md
.specbridge/scopes/issue-069-fresh-executor-source-run.scope.json
.specbridge/scopes/issue-067-source-backed-runtime-slice.scope.json
.specbridge/executor-handoffs/issue-069-fresh-executor-source-run.input.json
.specbridge/executor-packets/issue-069-fresh-executor-source-run-claude-source.executor-packet.json
.specbridge/runtime-launches/issue-069-fresh-executor-source-run.runtime-launch.json
.specbridge/runtime-evidence/issue-069-fresh-executor-source-run.claude-run.json
.specbridge/runtime-evidence/issue-069-fresh-executor-source-run.executor-output.md
.specbridge/runtime-results/issue-069-fresh-executor-source-run.runtime-result.json
.specbridge/runtime-summaries/issue-069-fresh-executor-source-run.runtime-summary.json
.specbridge/reports/issue-069-fresh-executor-source-run.final-report.json
.specbridge/audit-packets/issue-069-fresh-executor-source-run.audit-packet.json
.specbridge/audits/issue-069-fresh-executor-source-run.chatgpt-audit.json
.specbridge/context/CURRENT_GOAL.md
.specbridge/context/ACCEPTANCE_CRITERIA.md
docs/specbridge-fresh-executor-source-run.md
docs/specbridge-autonomy-backlog.md
docs/specbridge-runtime-launch-plans.md
docs/specbridge-runtime-results.md
docs/specbridge-runtime-summaries.md
docs/specbridge-test-results.md
README.md
specs/004-acceptance-tests.md
GitHub issue 69
GitHub pull request for this branch
```

## Executor Exclusive Write Scope

Claude Code may write only:

```text
docs/specbridge-fresh-executor-source-run.md
.specbridge/runtime-evidence/issue-069-fresh-executor-source-run.executor-output.md
```

All other allowed paths are coordinator-owned SpecBridge/Codex evidence and documentation updates.

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
Claude Code tools other than Read and Write
Claude Code writes outside the executor exclusive write scope
Antigravity session launch beyond the current local workspace
```

## Acceptance Criteria

- The task declares source, evidence, tests, docs, final report, audit packet, and ChatGPT/Codex audit paths before execution.
- SpecBridge prepares one executor packet for the fresh source run.
- SpecBridge prepares one runtime launch plan for the executor packet.
- Claude Code is invoked non-interactively with `Read` and `Write` tools only.
- Claude Code writes only `docs/specbridge-fresh-executor-source-run.md` and `.specbridge/runtime-evidence/issue-069-fresh-executor-source-run.executor-output.md`.
- The executor output records task id, contract id, written files, validations requested, policy result, unresolved risks, and completion status.
- SpecBridge records a runtime result from the fresh executor evidence.
- SpecBridge writes a runtime summary for the fresh runtime result.
- Local validations pass for executor packets, runtime launches, runtime results, runtime summaries, final reports, audit packets, ChatGPT audits, security gates, review gates, standard profile, smoke, and git diff whitespace.
- GitHub CI and deterministic review gates pass before merge.
- No secrets, production configuration, billing, auth security, dependency installation, database changes, CI/CD weakening, or deployment automation are involved.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-executor-packets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-launches.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-results.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-summaries.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-audit-packets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-chatgpt-audits.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contract-scopes.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 validate -Profile standard
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-security-gates.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-review-gate.ps1
git diff --check
```

## Stop Conditions

Execution must stop if Claude Code needs tools beyond Read/Write, writes outside the executor exclusive write scope, requires secrets, production configuration, billing, authentication or authorization security changes, dependency installation, database changes, CI/CD security changes, deployment automation, protected file changes, or scope outside the declared paths.

## Merge Policy

Gate-controlled automatic merge is allowed only after required gates pass.

Autonomous merge must not bypass CI, validation, policy checks, review gates, security gate validation, audit packet validation, ChatGPT audit validation, runtime result validation, runtime summary validation, or scope validation.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

The final report must include summary, changed files, validations, Claude runtime evidence, runtime result evidence, runtime summary evidence, policy result, risk result, merge status, deployment status, unresolved risks, and rollback notes if applicable.

## Completion Rule

This task is complete only when the fresh Claude executor output, runtime result, runtime summary, final report, audit packet, ChatGPT/Codex audit, local validations, GitHub CI, and policy-gated merge have passed.
