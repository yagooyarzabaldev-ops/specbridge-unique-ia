# SpecBridge PR Review Report Standard

## Purpose

This standard defines machine-readable PR review reports for SpecBridge.

The report format exists before live Claude/Codex review automation is activated. This keeps the automation boundary deterministic and auditable.

## Schema

PR review reports must conform to the existing schema:

```text
.specbridge/schemas/claude-review-output.schema.json
```

## Report Location

Review reports must be stored under:

```text
.specbridge/review-reports/
```

Files must use this suffix:

```text
.review-report.json
```

## Required Fields

Each report requires:

- `schema_version`
- `reviewer`
- `summary`
- `findings`
- `result`

Each finding requires:

- `severity`
- `category`
- `file`
- `evidence`
- `recommendation`
- `blocking`

## Allowed Result Values

```text
pass
fail
needs_human_review
```

## Blocking Rules

A report with `result: pass` must not contain blocking findings.

A report with `result: fail` must contain at least one blocking finding.

`needs_human_review` may contain blocking or non-blocking findings.

## Current Boundary

This standard does not activate live Claude, Codex, MCP, secrets, or deployment automation.

It only defines and validates the review artifact format.
