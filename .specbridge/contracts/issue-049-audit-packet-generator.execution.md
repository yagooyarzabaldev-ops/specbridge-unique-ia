# Execution Contract: Issue 49

## Contract Metadata

- contract_id: issue-049-audit-packet-generator
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/49
- created_by: ChatGPT/Codex
- created_at: 2026-05-20
- autonomy_profile: full_autopilot
- risk_level: low
- status: ready_for_execution

## Goal

Add deterministic audit packet generation so ChatGPT/Codex can audit Claude Code output from repository evidence.

## Context

The autonomy backlog identifies the Audit Packet Generator as the next task after contract scope validation. Audit packets must bundle evidence from execution contracts, changed files, validation results, final reports, CI status, policy result, and unresolved risks without embedding raw secrets or file contents.

## Source References

- README.md
- SPECBRIDGE.md
- .specbridge/policy.yaml
- .specbridge/context/audit-packet-standard.md
- .specbridge/context/CURRENT_GOAL.md
- .specbridge/context/ACCEPTANCE_CRITERIA.md
- docs/specbridge-autonomy-backlog.md
- docs/specbridge-contract-scope-validator.md

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

```text
low
```

Reason:

- governance scripts, docs, schemas, packet artifacts, and tests only
- no runtime product implementation code
- no secrets
- no production configuration
- no billing
- no authentication or authorization changes
- no CI/CD security weakening

## Allowed Scope

```text
scripts/generate-audit-packet.ps1
scripts/validate-audit-packets.ps1
scripts/test-specbridge-negative-validations.ps1
scripts/specbridge-smoke.ps1
scripts/validate-schemas.ps1
.specbridge/schemas/audit-packet.schema.json
.specbridge/audit-packets/issue-049-audit-packet-generator.audit-packet.json
.specbridge/context/audit-packet-standard.md
.specbridge/context/CURRENT_GOAL.md
.specbridge/context/ACCEPTANCE_CRITERIA.md
.specbridge/scopes/issue-049-audit-packet-generator.scope.json
.specbridge/contracts/issue-049-audit-packet-generator.execution.md
.specbridge/reports/issue-049-audit-packet-generator.final-report.json
docs/specbridge-audit-packet-generator.md
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
runtime product code
package installation
hosted dashboard implementation
MCP server implementation
GitHub App implementation
database schema implementation
authentication implementation
authorization implementation
billing implementation
deployment automation
CI/CD security weakening
branch protection weakening
raw secret capture
raw file content capture
raw diff embedding
```

## Acceptance Criteria

- `scripts/generate-audit-packet.ps1` exists.
- `scripts/validate-audit-packets.ps1` exists.
- `.specbridge/schemas/audit-packet.schema.json` exists and is part of schema validation.
- Audit packets include task id, execution contract path, changed files, diff summary, validation commands, validation results, final report path, CI status, PR review report path, policy result, unresolved risks, completion status, and source file references.
- Audit packets reference files by repository-relative path.
- Audit packets do not embed raw diffs, file contents, secrets, tokens, private keys, or credential values.
- Positive fixture generation passes and validates.
- Negative validation covers missing execution contract, missing packet fields, and raw diff field rejection.
- Smoke validation runs audit packet validation.
- Required validations pass locally.

## Required Validations

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/validate-foundation.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-contract-scopes.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-schemas.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-audit-packets.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-pr-review-reports.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-claude-review-workflow.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-autonomous-execution-protocol.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-review-gate.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/test-specbridge-negative-validations.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
git diff --check
```

## Stop Conditions

Execution must stop if the task requires runtime product code, secrets, production deployment, billing changes, authentication implementation, authorization implementation, branch protection weakening, CI/CD security weakening, hosted dashboard implementation, MCP server implementation, GitHub App implementation, database schema implementation, autonomous deployment, or raw secret capture.

## Merge Policy

Gate-controlled automatic merge is allowed only after required gates pass.

Autonomous merge must not bypass CI, validation, policy checks, review gates, audit packet validation, or scope validation.

## Deployment Policy

No deployment is allowed.

```text
staging: disabled
production: disabled
```

## Final Report Requirements

The final report must include summary, changed files, validations, policy result, risk result, unresolved risks, merge status, deployment status, and completion status.

## Completion Rule

This task is complete only when the audit packet generator and validator exist, committed audit packet evidence validates, required positive and negative fixtures pass, smoke validation includes audit packet validation, local validation evidence is recorded, the final report validates, and the branch is pushed to GitHub.
