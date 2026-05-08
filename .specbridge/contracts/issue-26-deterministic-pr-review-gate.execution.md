# Execution Contract: Issue 26

## Contract Metadata

- contract_id: issue-26-deterministic-pr-review-gate
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/26
- created_by: ChatGPT/Codex
- created_at: 2026-05-07
- autonomy_profile: assisted
- risk_level: low
- status: draft

## Goal

Add an active deterministic PR review gate for SpecBridge.

## Context

SpecBridge now has foundation validation, contract validation, schema validation, final report validation, a smoke runner, and a controlled E2E pilot. The next safe step is an active deterministic PR-level gate that checks for blocked scopes before introducing AI-assisted review workflows.

## Source References

- docs/claude-code-ci-workflow.md
- docs/specbridge-controlled-e2e-pilot.md
- GitHub issue #26

## Autonomy Profile

```text
assisted
```

## Risk Level

```text
low
```

Reason:

- deterministic review only
- no live Claude execution
- no live Codex review
- no MCP server implementation
- no secrets
- no production configuration
- no deployment automation
- no application runtime code

## Allowed Scope

```text
scripts/validate-review-gate.ps1
.github/workflows/specbridge-review-gate.yml
docs/specbridge-review-gate.md
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

- `scripts/validate-review-gate.ps1` exists.
- `.github/workflows/specbridge-review-gate.yml` exists.
- `docs/specbridge-review-gate.md` exists.
- A final report artifact exists for this task.
- Foundation validation passes.
- Contract validation passes.
- Schema validation passes.
- Final report validation passes.
- Smoke validation passes.
- Review gate validation passes locally.
- CI passes on the pull request.
- No live Claude/Codex/MCP automation is activated.

## Required Validations

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/validate-foundation.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-schemas.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
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
- Smoke validation passed.
- Review gate validation passed.
- CI passed.
- PR references and closes GitHub issue #26.

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

This task is complete only when the deterministic review gate exists, validation passes locally, CI passes, and the PR is merged into `main`.
