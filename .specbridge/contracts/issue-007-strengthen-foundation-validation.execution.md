# Execution Contract: Issue 007

## Contract Metadata

- contract_id: issue-007-strengthen-foundation-validation
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/7
- created_by: ChatGPT/Codex
- created_at: 2026-05-07
- autonomy_profile: vibe_autopilot
- risk_level: low
- status: draft

## Goal

Strengthen foundation validation so accidental Markdown escaping is detected automatically.

## Context

Several foundation Markdown files were previously created with accidental rendered-Markdown escaping.

The existing foundation validator checks required files, non-empty files, balanced code fences, and absence of implementation code. It must now also detect common escaped Markdown artifacts.

## Source References

- scripts/validate-foundation.ps1
- .specbridge/execution-contract-template.md
- .specbridge/contracts/example-issue-003.execution.md
- .specbridge/contracts/issue-005-branch-protection.execution.md
- GitHub issue #7

## Autonomy Profile

```text
vibe_autopilot
```

## Risk Level

```text
low
```

Reason:

- validation script change only
- no product implementation code
- no secrets
- no production configuration
- no infrastructure change
- no database change

## Allowed Scope

```text
scripts/validate-foundation.ps1
.specbridge/contracts/**
docs/**
specs/**
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
```

## Acceptance Criteria

- The foundation validator detects escaped Markdown heading markers.
- The foundation validator detects escaped Markdown list markers.
- The foundation validator detects escaped underscores in identifier-like content.
- The foundation validator detects escaped wildcard markers in path or scope examples.
- The validator excludes `.git` paths.
- The validator passes on the current repository.
- No product implementation code is added.

## Required Validations

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/validate-foundation.ps1
```

## Stop Conditions

Execution must stop if validation fails on clean foundation files or if the change requires modifying blocked scope.

## Merge Policy

Human-controlled merge during foundation phase.

Minimum conditions:

- Foundation validation passed.
- CI passed.
- No product implementation code added.
- PR references and closes GitHub issue #7.

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

This task is complete only when validation passes locally, CI passes, and the PR is merged into `main`.
