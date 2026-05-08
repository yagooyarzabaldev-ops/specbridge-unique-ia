# Execution Contract: Issue 30

## Contract Metadata

- contract_id: issue-30-pr-review-report-validation
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/30
- created_by: ChatGPT/Codex
- created_at: 2026-05-07
- autonomy_profile: assisted
- risk_level: low
- status: draft

## Goal

Add deterministic validation for machine-readable PR review report artifacts.

## Context

SpecBridge already has foundation validation, contract validation, schema validation, final report validation, a smoke runner, a controlled E2E pilot, and a deterministic PR review gate. The next safe step is to define and validate machine-readable PR review reports before activating live Claude/Codex review automation.

## Source References

- .specbridge/schemas/claude-review-output.schema.json
- docs/claude-code-ci-workflow.md
- GitHub issue #30

## Autonomy Profile

```text
assisted
```

## Risk Level

```text
low
```

Reason:

- deterministic artifact validation only
- no live Claude execution
- no live Codex review
- no MCP server implementation
- no secrets
- no production configuration
- no deployment automation
- no application runtime code

## Allowed Scope

```text
scripts/validate-pr-review-reports.ps1
docs/specbridge-pr-review-report-standard.md
.specbridge/review-reports/**
.specbridge/contracts/**
.specbridge/reports/**
.github/workflows/foundation-validation.yml
scripts/specbridge-smoke.ps1
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

- `scripts/validate-pr-review-reports.ps1` exists.
- `docs/specbridge-pr-review-report-standard.md` exists.
- A sample PR review report artifact exists.
- A final report artifact exists for this task.
- Foundation validation passes.
- Contract validation passes.
- Schema validation passes.
- Final report validation passes.
- PR review report validation passes.
- Smoke validation passes.
- Review gate validation passes.
- CI passes on the pull request.
- No live Claude/Codex/MCP automation is activated.

## Required Validations

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/validate-foundation.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-schemas.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-pr-review-reports.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-review-gate.ps1
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
- PR review report validation passed.
- Smoke validation passed.
- Review gate validation passed.
- CI passed.
- PR references and closes GitHub issue #30.

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

This task is complete only when PR review report validation exists, validation passes locally, CI passes, and the PR is merged into `main`.
