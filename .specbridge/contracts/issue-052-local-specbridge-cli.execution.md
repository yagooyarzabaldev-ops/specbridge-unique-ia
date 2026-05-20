# Execution Contract: Issue 52

## Contract Metadata

- contract_id: issue-052-local-specbridge-cli
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/52
- created_by: ChatGPT/Codex
- created_at: 2026-05-20
- autonomy_profile: full_autopilot
- risk_level: medium
- status: ready_for_execution

## Goal

Implement the first local file-backed SpecBridge CLI surface with deterministic commands for status, validation, contract creation, final report creation, audit packet generation, conflict detection, task decomposition, and review gates.

## Context

The autonomy backlog identifies the Local SpecBridge CLI as the next task after Security Review Gate Expansion. Existing validators, audit packet generation, scope validation, ChatGPT audit validation, and security gates are available. The missing layer is a local operator command surface that wraps these capabilities without requiring secrets, network calls, package installation, hosted services, MCP runtime, or production access.

## Source References

- README.md
- SPECBRIDGE.md
- AGENTS.md
- .specbridge/policy.yaml
- docs/specbridge-v4-product-contract.md
- docs/specbridge-autonomy-backlog.md
- docs/specbridge-security-review-gate-expansion.md
- .specbridge/context/CURRENT_GOAL.md
- .specbridge/context/ACCEPTANCE_CRITERIA.md

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
medium
```

Reason:

- the task adds the first local runtime command surface
- implementation remains limited to PowerShell scripts, validation fixtures, docs, and governed artifact files
- no dependency installation, package runtime, hosted service, MCP server, GitHub App, secrets, production configuration, billing, authentication implementation, authorization implementation, or deployment automation is added
- CLI writes only declared repository artifact paths

## Allowed Scope

```text
scripts/specbridge.ps1
scripts/test-specbridge-cli.ps1
scripts/specbridge-smoke.ps1
.specbridge/context/CURRENT_GOAL.md
.specbridge/context/ACCEPTANCE_CRITERIA.md
.specbridge/scopes/issue-052-local-specbridge-cli.scope.json
.specbridge/contracts/issue-052-local-specbridge-cli.execution.md
.specbridge/reports/issue-052-local-specbridge-cli.final-report.json
.specbridge/audit-packets/issue-052-local-specbridge-cli.audit-packet.json
.specbridge/audits/issue-052-local-specbridge-cli.chatgpt-audit.json
docs/specbridge-local-cli.md
docs/specbridge-autonomy-backlog.md
docs/specbridge-test-matrix.md
docs/specbridge-test-results.md
specs/004-acceptance-tests.md
```

## Blocked Scope

```text
.env
.env.*
secrets/**
infra/prod/**
src/**
app/**
apps/**
packages/**
lib/**
server/**
client/**
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
raw secret capture
raw file content capture
network calls by default
```

## Acceptance Criteria

- `scripts/specbridge.ps1` exists.
- The CLI supports `status`, `validate`, `create-contract`, `create-report`, `audit-packet`, `detect-conflicts`, `decompose-task`, and `review-gate`.
- Commands have deterministic exit codes.
- Commands use declared input and output paths.
- Commands do not require secrets.
- The CLI avoids network calls by default.
- `status` returns structured JSON.
- `validate` exposes deterministic validation profiles.
- `create-contract` writes only `.specbridge/contracts/*.execution.md`.
- `create-report` writes only `.specbridge/reports/*.final-report.json`.
- `audit-packet` delegates to the existing audit packet generator.
- `detect-conflicts` delegates to contract scope validation.
- `decompose-task` writes only `.specbridge/decompositions/*.decomposition.json` and rejects duplicate write paths.
- `review-gate` runs security and PR review gates.
- `scripts/test-specbridge-cli.ps1` covers every CLI command.
- `scripts/specbridge-smoke.ps1` runs the CLI validation suite.
- Required validations pass locally.

## Required Validations

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 status
powershell -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 validate -Profile standard
powershell -ExecutionPolicy Bypass -File ./scripts/test-specbridge-cli.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-foundation.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-contract-scopes.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-schemas.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-audit-packets.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-chatgpt-audits.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-security-gates.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-pr-review-reports.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-claude-review-workflow.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-autonomous-execution-protocol.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-review-gate.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/test-specbridge-negative-validations.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
git diff --check
```

## Stop Conditions

Execution must stop if the task requires secrets, production deployment, billing changes, authentication implementation, authorization implementation, branch protection weakening, CI/CD permission escalation, CI/CD security weakening, hosted dashboard implementation, MCP server implementation, GitHub App implementation, database schema implementation, dependency installation, package runtime selection outside this script contract, autonomous deployment, raw secret capture, raw file content capture, or default network calls.

## Merge Policy

Gate-controlled automatic merge is allowed only after required gates pass.

Autonomous merge must not bypass CI, validation, policy checks, review gates, security gate validation, CLI tests, audit packet validation, ChatGPT audit validation, or scope validation.

## Deployment Policy

No deployment is allowed.

```text
staging: disabled
production: disabled
```

## Final Report Requirements

The final report must include summary, changed files, validations, policy result, risk result, unresolved risks, merge status, deployment status, and completion status.

## Completion Rule

This task is complete only when the local CLI exists, every required command is covered by tests, smoke validation runs the CLI suite, local validation evidence is recorded, final report and audit evidence validate, and the branch is pushed to GitHub.
