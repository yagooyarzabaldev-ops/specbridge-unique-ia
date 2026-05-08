# Execution Contract: Issue 22

## Contract Metadata

- contract_id: issue-22-final-report-validation
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/22
- created_by: ChatGPT/Codex
- created_at: 2026-05-07
- autonomy_profile: assisted
- risk_level: low
- status: draft

## Goal

Add deterministic validation for SpecBridge final reports so every controlled execution leaves auditable completion evidence.

## Context

SpecBridge already validates foundation files, execution contracts, schemas, and the local smoke runner. The next safe step is validating final reports before any live Claude Code, Codex, MCP, or agentic execution is activated.

## Source References

- docs/specbridge-v2-roadmap.md
- docs/specbridge-test-protocol.md
- .specbridge/schemas/final-report.schema.json
- GitHub issue #22

## Autonomy Profile

```text
assisted
```

## Risk Level

```text
low
```

Reason:

- validation and documentation only
- no product runtime code
- no secrets
- no production configuration
- no deployment automation
- no MCP server implementation
- no live Claude/Codex workflow activation

## Allowed Scope

```text
scripts/validate-final-reports.ps1
scripts/specbridge-smoke.ps1
docs/specbridge-final-report-standard.md
.github/workflows/foundation-validation.yml
.specbridge/reports/**
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

- `scripts/validate-final-reports.ps1` exists.
- `docs/specbridge-final-report-standard.md` exists.
- `.specbridge/reports/example-final-report.final-report.json` exists.
- Foundation workflow includes the final report validation step.
- Smoke runner includes the final report validation step.
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

Execution must stop if blocked scope must be modified, secrets are required, production configuration is required, live Claude/Codex execution must be activated, MCP implementation is required, or deterministic validation cannot pass safely.

## Merge Policy

Human-controlled merge during foundation phase.

Minimum conditions:

- Foundation validation passed.
- Contract validation passed.
- Schema validation passed.
- Final report validation passed.
- Smoke validation passed.
- CI passed.
- PR references and closes GitHub issue #22.

## Deployment Policy

No deployment is allowed for this task.

```text
staging: disabled
production: disabled
```

## Final Report Requirements

The final report must include:

- summary
- changed files
- validation result
- policy result
- risk result
- unresolved risks
- completion status

## Completion Rule

This task is complete only when the final report validator exists, the standard exists, the sample report exists, validation passes locally, CI passes, and the PR is merged into `main`.
