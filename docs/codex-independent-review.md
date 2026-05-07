# Codex Independent Review Standard

## Purpose

This document defines the future Codex independent review role in SpecBridge.

## Principle

Execution and review should be separated.

```text
Claude Code executes.
Codex reviews.
CI validates.
SpecBridge reports.
```

## Review Inputs

Codex review should receive:

- execution contract
- PR diff
- validation logs
- policy files
- changed file list
- final report draft

## Review Outputs

Codex review output must conform to:

```text
.specbridge/schemas/codex-review-output.schema.json
```

## Review Categories

Allowed categories:

- contract compliance
- policy compliance
- validation evidence
- risk classification
- missing acceptance criteria
- blocked scope violation
- unsafe autonomy

## Blocking Rules

Codex may block when:

- execution contract is incomplete
- changed files exceed allowed scope
- validation is missing or failed
- final report claims unsupported success
- risk level is understated
- production or secret handling appears unexpectedly

## Current Status

This is a design standard only.

No Codex automated workflow is active yet.
