# Execution Contract: Issue 36

## Contract Metadata

- contract_id: issue-36-non-blocking-claude-review
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/36
- created_by: ChatGPT/Codex
- created_at: 2026-05-07
- autonomy_profile: assisted
- risk_level: medium
- status: draft

## Goal

Add a non-blocking Claude review workflow for pull requests.

## Context

SpecBridge now has protected branches, deterministic validation, review gates, machine-readable review reports, generated review artifacts, and PR comment publishing. The next step is a live Claude review workflow constrained to review-only behavior.

## Source References

- docs/claude-code-ci-workflow.md
- docs/specbridge-pr-review-comment-publishing.md
- GitHub issue #36
- Anthropic Claude Code GitHub Actions documentation

## Autonomy Profile

```text
assisted
```

## Risk Level

```text
medium
```

Reason:

- introduces live external AI review
- uses provider API secret if configured
- remains non-blocking
- does not request contents write permission
- does not push, merge, deploy, or edit files

## Allowed Scope

```text
.github/workflows/claude-review-non-blocking.yml
.github/workflows/foundation-validation.yml
scripts/validate-claude-review-workflow.ps1
scripts/validate-review-gate.ps1
scripts/specbridge-smoke.ps1
docs/specbridge-non-blocking-claude-review.md
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
live Claude Code execution workflow that edits files
live Codex execution workflow
MCP server implementation
contents write permission
automatic merge
automatic push
```

## Acceptance Criteria

- `.github/workflows/claude-review-non-blocking.yml` exists.
- `scripts/validate-claude-review-workflow.ps1` exists.
- `docs/specbridge-non-blocking-claude-review.md` exists.
- The workflow uses `anthropics/claude-code-action@v1`.
- The workflow uses `ANTHROPIC_API_KEY` only as a GitHub Actions secret.
- The workflow is non-blocking.
- The workflow does not request `contents: write`.
- The workflow skips safely if `ANTHROPIC_API_KEY` is not configured.
- Foundation validation passes.
- Contract validation passes.
- Schema validation passes.
- Final report validation passes.
- PR review report validation passes.
- Claude review workflow validation passes.
- Smoke validation passes.
- Review gate validation passes.
- CI passes on the pull request.

## Required Validations

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/validate-foundation.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-schemas.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-pr-review-reports.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-claude-review-workflow.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-review-gate.ps1
```

## Stop Conditions

Execution must stop if contents write permission is required, file-editing automation is required, production configuration is required, deployment automation is required, autonomous merge/push is required, or validation cannot pass safely.

## Merge Policy

Human-controlled merge.

Minimum conditions:

- Foundation validation passed.
- Contract validation passed.
- Schema validation passed.
- Final report validation passed.
- PR review report validation passed.
- Claude review workflow validation passed.
- Smoke validation passed.
- Review gate validation passed.
- CI passed.
- PR references and closes GitHub issue #36.

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

This task is complete only when the non-blocking Claude review workflow exists, validation passes locally, CI passes, and the PR is merged into `main`.
