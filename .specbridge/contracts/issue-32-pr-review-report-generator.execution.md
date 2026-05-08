# Execution Contract: Issue 32

## Contract Metadata

- contract_id: issue-32-pr-review-report-generator
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/32
- created_by: ChatGPT/Codex
- created_at: 2026-05-07
- autonomy_profile: assisted
- risk_level: low
- status: draft

## Goal

Add a deterministic PR review report generator workflow.

## Context

SpecBridge already validates PR review report artifacts. The next safe step is a non-invasive generator workflow that produces a schema-conformant review artifact on pull requests without activating live Claude, Codex, MCP, secrets, deployment automation, or runtime application code.

## Source References

- .specbridge/schemas/claude-review-output.schema.json
- docs/specbridge-pr-review-report-standard.md
- GitHub issue #32

## Autonomy Profile

```text
assisted
```

## Risk Level

```text
low
```

Reason:

- deterministic report generation only
- no live Claude execution
- no live Codex review
- no MCP server implementation
- no secrets
- no production configuration
- no deployment automation
- no application runtime code

## Allowed Scope

```text
scripts/generate-pr-review-report.ps1
scripts/validate-pr-review-reports.ps1
.github/workflows/specbridge-pr-review-report.yml
docs/specbridge-pr-review-report-generator.md
.specbridge/contracts/**
.specbridge/reports/**
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

- `scripts/generate-pr-review-report.ps1` exists.
- `.github/workflows/specbridge-pr-review-report.yml` exists.
- `docs/specbridge-pr-review-report-generator.md` exists.
- Generated PR review report validates successfully.
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
powershell -ExecutionPolicy Bypass -File ./scripts/generate-pr-review-report.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-pr-review-reports.ps1 -ReportsPath .specbridge/generated-review-reports
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
- Generated PR review report validation passed.
- CI passed.
- PR references and closes GitHub issue #32.

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

This task is complete only when the deterministic generator exists, generated reports validate locally, CI passes, and the PR is merged into `main`.
