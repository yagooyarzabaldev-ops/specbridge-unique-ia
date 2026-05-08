# Execution Contract: Issue 34

## Contract Metadata

- contract_id: issue-34-pr-review-comment-publishing
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/34
- created_by: ChatGPT/Codex
- created_at: 2026-05-07
- autonomy_profile: assisted
- risk_level: low
- status: draft

## Goal

Add non-invasive PR comment publishing for deterministic SpecBridge review reports.

## Context

SpecBridge now generates and validates machine-readable PR review report artifacts in CI. The next safe step is to render that report into a stable Markdown comment and publish it to the pull request conversation using only the GitHub Actions token.

## Source References

- docs/specbridge-pr-review-report-generator.md
- docs/specbridge-pr-review-report-standard.md
- GitHub issue #34

## Autonomy Profile

```text
assisted
```

## Risk Level

```text
low
```

Reason:

- deterministic PR comment publishing only
- GitHub Actions token only
- no user secrets
- no live Claude execution
- no live Codex review
- no MCP server implementation
- no production configuration
- no deployment automation
- no application runtime code

## Allowed Scope

```text
scripts/render-pr-review-comment.ps1
scripts/publish-pr-review-comment.ps1
.github/workflows/specbridge-pr-review-report.yml
docs/specbridge-pr-review-comment-publishing.md
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
user-provided secrets
```

## Acceptance Criteria

- `scripts/render-pr-review-comment.ps1` exists.
- `scripts/publish-pr-review-comment.ps1` exists.
- `docs/specbridge-pr-review-comment-publishing.md` exists.
- PR review report workflow renders the Markdown comment.
- PR review report workflow publishes or updates a PR comment using the GitHub Actions token.
- Foundation validation passes.
- Contract validation passes.
- Schema validation passes.
- Final report validation passes.
- PR review report validation passes.
- Smoke validation passes.
- Review gate validation passes.
- Generated PR review report validation passes.
- PR comment rendering passes locally.
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
powershell -ExecutionPolicy Bypass -File ./scripts/render-pr-review-comment.ps1
```

## Stop Conditions

Execution must stop if blocked scope must be modified, user secrets are required, production configuration is required, live Claude/Codex execution must be activated, MCP implementation is required, or deterministic validation cannot pass safely.

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
- PR comment rendering passed.
- CI passed.
- PR references and closes GitHub issue #34.

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

This task is complete only when PR review report comments are rendered and published in CI, validation passes locally, CI passes, and the PR is merged into `main`.
