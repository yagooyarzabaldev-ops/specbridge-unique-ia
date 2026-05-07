---
name: specbridge-contract-review
description: Review a SpecBridge execution contract for completeness, policy alignment, and validation readiness.
context: fork
allowed-tools:
  - Read
  - Grep
  - Glob
argument-hint: path to a .specbridge/contracts/*.execution.md file
---

# SpecBridge Contract Review Skill

## Purpose

Review a SpecBridge execution contract before implementation or merge.

This skill should run in isolated context so exploratory review output does not pollute the main Claude Code session.

## Inputs

Expected input:

```text
.specbridge/contracts/<contract>.execution.md
```

## Review Checklist

Check that the contract includes:

- Contract Metadata
- Goal
- Context
- Source References
- Autonomy Profile
- Risk Level
- Allowed Scope
- Blocked Scope
- Acceptance Criteria
- Required Validations
- Stop Conditions
- Merge Policy
- Deployment Policy
- Final Report Requirements
- Completion Rule

## Policy Review

Verify:

- allowed scope is explicit
- blocked scope is explicit
- risk level is compatible with autonomy profile
- production deployment is not assumed
- validation commands are listed
- stop conditions are present
- final report requirements are concrete

## Output Format

Return:

```text
status: pass | fail
missing_sections: ...
policy_findings: ...
risk_findings: ...
validation_findings: ...
recommendation: proceed | revise | block
```

## Rules

Do not modify files.

Do not execute implementation.

Report evidence from the contract text.