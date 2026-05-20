# Execution Contract: Issue 53

## Contract Metadata

- contract_id: issue-053-controlled-implementation-pilot
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/53
- created_by: ChatGPT/Codex
- created_at: 2026-05-20
- autonomy_profile: full_autopilot
- risk_level: medium
- status: ready_for_execution

## Goal

Run the first controlled implementation pilot by adding one small useful CLI feature, validating it locally, recording evidence, auditing the result, and allowing automatic merge only after repository gates pass.

## Context

The local SpecBridge CLI is complete. The autonomy backlog now requires a small real implementation to prove the intended ChatGPT/Codex governed, Claude Code implemented, GitHub validated, ChatGPT/Codex audited loop before attempting multi-agent parallel execution.

The pilot feature is `status -IncludeLatestArtifacts`, which extends the local CLI status command with deterministic latest artifact paths for operators and future orchestration layers.

## Source References

- README.md
- SPECBRIDGE.md
- AGENTS.md
- .specbridge/policy.yaml
- .specbridge/context/CURRENT_GOAL.md
- .specbridge/context/ACCEPTANCE_CRITERIA.md
- docs/specbridge-autonomy-backlog.md
- docs/specbridge-local-cli.md
- docs/specbridge-test-matrix.md

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
medium
```

Reason:

- the task changes a local runtime script
- the implementation is intentionally small and isolated
- the test suite covers the changed command path
- no dependency installation, hosted service, MCP server, GitHub App, database schema, secrets, production configuration, billing, authentication implementation, authorization implementation, or deployment automation is added

## Allowed Scope

```text
scripts/specbridge.ps1
scripts/test-specbridge-cli.ps1
.specbridge/context/CURRENT_GOAL.md
.specbridge/context/ACCEPTANCE_CRITERIA.md
.specbridge/scopes/issue-053-controlled-implementation-pilot.scope.json
.specbridge/contracts/issue-053-controlled-implementation-pilot.execution.md
.specbridge/reports/issue-053-controlled-implementation-pilot.final-report.json
.specbridge/audit-packets/issue-053-controlled-implementation-pilot.audit-packet.json
.specbridge/audits/issue-053-controlled-implementation-pilot.chatgpt-audit.json
docs/specbridge-controlled-implementation-pilot.md
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

- `scripts/specbridge.ps1 status` accepts `-IncludeLatestArtifacts`.
- The status output includes `latest_artifacts` only when the switch is provided.
- `latest_artifacts` includes `contract`, `scope`, `final_report`, `audit_packet`, and `chatgpt_audit`.
- Latest artifact selection is deterministic and orders `issue-<number>` file names by numeric issue number before file name.
- Missing artifact directories or empty artifact categories return null for that category.
- Returned paths are repository-relative.
- `scripts/test-specbridge-cli.ps1` covers `status -IncludeLatestArtifacts`.
- Documentation records the pilot and the CLI switch.
- Final report, audit packet, and ChatGPT audit evidence are present and valid.
- Required validations pass locally.

## Required Validations

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 status -IncludeLatestArtifacts
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

This task is complete only when the small CLI feature exists, local test evidence is recorded, final report and audit evidence validate, CI passes on GitHub, ChatGPT/Codex audit is non-blocking, and the pull request is merged by policy gates.
