# Execution Contract: Issue 20

## Contract Metadata

- contract_id: issue-20-specbridge-local-smoke-runner
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/20
- created_by: ChatGPT/Codex
- created_at: 2026-05-07
- autonomy_profile: assisted
- risk_level: low
- status: draft

## Goal

Add a local SpecBridge smoke runner and test protocol so the connector can be tested end-to-end through the existing foundation workflow.

## Context

SpecBridge already has foundation, contract, and schema validation active in CI. The next safe step is a local smoke runner that executes the deterministic validation chain without activating live Claude Code, Codex, MCP, secrets, deployment, or production automation.

## Source References

- docs/specbridge-v2-roadmap.md
- docs/context-management.md
- docs/e2e-pilot-plan.md
- GitHub issue #20

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
- no live Claude/Codex workflow activation

## Allowed Scope

```text
scripts/specbridge-smoke.ps1
docs/specbridge-test-protocol.md
.github/workflows/foundation-validation.yml
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

- `scripts/specbridge-smoke.ps1` exists.
- `docs/specbridge-test-protocol.md` exists.
- Foundation workflow includes the smoke validation step.
- Foundation validation passes.
- Contract validation passes.
- Schema validation passes.
- Smoke validation passes.
- CI passes on the pull request.
- No live Claude/Codex/MCP automation is activated.

## Required Validations

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/validate-foundation.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-schemas.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
```

## Stop Conditions

Execution must stop if blocked scope must be modified, secrets are required, production configuration is required, live Claude/Codex execution must be activated, or deterministic validation cannot pass safely.

## Merge Policy

Human-controlled merge during foundation phase.

Minimum conditions:

- Foundation validation passed.
- Contract validation passed.
- Schema validation passed.
- Smoke validation passed.
- CI passed.
- PR references and closes GitHub issue #20.

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

This task is complete only when the smoke runner exists, the test protocol exists, validation passes locally, CI passes, and the PR is merged into `main`.
