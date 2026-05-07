# Claude Code Pull Request Review Standard

## Purpose

This document defines how Claude Code should review pull requests in SpecBridge.

This document does not activate review automation.

## Review Goals

Claude Code PR review should verify:

- execution contract compliance
- changed files stay inside allowed scope
- blocked scope is not modified
- validations are present
- risk level is accurate
- final report is evidence-based

## Required Inputs

A review should receive:

- PR diff
- related issue
- execution contract
- changed file list
- validation output
- policy files

## Output

Review output must conform to:

```text
.specbridge/schemas/claude-review-output.schema.json
```

## Finding Requirements

Every finding must include:

- severity
- category
- file
- line or section
- evidence
- recommendation
- blocking flag

## Blocking Rules

Block only when:

- contract is violated
- validation failed
- blocked scope changed
- secrets or production config are exposed
- high or critical risk is introduced without policy authorization

Do not block on minor style issues.

## Review Independence

The reviewer should not be the same agent session that produced the implementation.

## Current Status

This is a review standard only.

Workflow activation is intentionally deferred.
