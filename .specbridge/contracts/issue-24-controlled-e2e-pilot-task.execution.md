# Execution Contract: Issue 24

## Contract Metadata

- contract_id: issue-24-controlled-e2e-pilot-task
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/24
- created_by: ChatGPT/Codex
- created_at: 2026-05-07
- autonomy_profile: assisted
- risk_level: low
- status: draft

## Goal

Add a controlled end-to-end pilot task that proves SpecBridge can execute the full governance loop using a real issue, execution contract, final report artifact, deterministic validations, pull request, CI, and human-controlled merge.

## Context

SpecBridge now has deterministic validation for foundation files, execution contracts, schemas, final reports, and a local smoke runner. This issue validates the process as a complete controlled pilot without activating live Claude Code, Codex, MCP, secrets, production deployment, or runtime application code.

## Source References

- docs/specbridge-test-protocol.md
- docs/specbridge-final-report-standard.md
- docs/e2e-pilot-plan.md
- GitHub issue #24

## Autonomy Profile

```text
assisted
```

## Risk Level

```text
low
```

Reason:

- documentation and governance artifact only
- no product runtime code
- no secrets
- no production configuration
- no deployment automation
- no live Claude/Codex workflow activation
- no MCP server implementation

## Allowed Scope

```text
docs/specbridge-controlled-e2e-pilot.md
.specbridge/reports/issue-24-controlled-e2e-pilot.final-report.json
.specbridge/contracts/**
```

## Blocked Scope

```text
.env
.env.*
secrets/**
infra/prod/**
application source code
runtime framework setup
package installation
deployment automation
database schema implementation
live Claude Code execution workflow activation
live Codex review workflow activation
MCP server implementation
```

## Acceptance Criteria

- Controlled E2E pilot documentation exists.
- Pilot final report artifact exists.
- Execution contract exists for issue #24.
- Foundation validation passes.
- Contract validation passes.
- Schema validation passes.
- Final report validation passes.
- Smoke validation passes.
- CI passes on the pull request.
- No live Claude/Codex/MCP automation is activated.

## Required Validations

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/validate-foundation.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-schemas.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
```

## Stop Conditions

Execution must stop if blocked scope must be modified, secrets are required, production configuration is required, live Claude/Codex execution must be activated, MCP server implementation is required, or deterministic validation cannot pass safely.

## Merge Policy

Human-controlled merge during foundation phase.

Minimum conditions:

- Foundation validation passed.
- Contract validation passed.
- Schema validation passed.
- Final report validation passed.
- Smoke validation passed.
- CI passed.
- PR references and closes GitHub issue #24.

## Deployment Policy

No deployment is allowed for this task.

```text
staging: disabled
production: disabled
```

## Final Report Requirements

The final report must include:

- summary
- changed_files
- validations
- policy_result
- risk_result
- unresolved_risks
- merge_status
- deployment_status
- completion_status

## Completion Rule

This task is complete only when the pilot documentation exists, the pilot final report artifact exists, validation passes locally, CI passes, and the PR is merged into `main`.
