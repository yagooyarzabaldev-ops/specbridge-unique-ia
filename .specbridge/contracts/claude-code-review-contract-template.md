# Claude Code Review Contract Template

## Review Metadata

- review_id:
- related_pr:
- related_issue:
- contract_path:
- reviewer:
- created_at:
- status:

## Purpose

Define the Claude Code PR review task.

## Inputs

- PR diff
- execution contract
- changed files
- validation output
- policy files

## Output Schema

```text
.specbridge/schemas/claude-review-output.schema.json
```

## Review Criteria

- contract compliance
- policy compliance
- validation evidence
- risk classification
- blocked scope changes
- unsupported success claims

## Stop Conditions

Stop if required inputs are missing or output cannot be validated.
