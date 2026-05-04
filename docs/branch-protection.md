# Branch Protection Policy

## Purpose

This document defines the required protection policy for the `main` branch.

SpecBridge relies on policy, CI, review, and auditability. The repository must not allow changes to reach `main` without passing required validation gates.

## Protected Branch

```text
main
```

## Required Rules

The `main` branch must require pull requests before merge.

The `main` branch must require status checks before merge.

Required status check:

```text
Foundation Validation / validate-foundation
```

The `main` branch must reject force pushes.

The `main` branch must reject branch deletion.

Direct pushes to `main` should be blocked unless explicitly required by repository administrators.

## Rationale

SpecBridge is designed for autonomous and semi-autonomous development workflows.

If agents can produce pull requests and users can delegate execution, the repository must enforce validation at the GitHub level.

CI must be a hard gate, not a suggestion.

## Minimum Merge Conditions

A pull request may be merged into `main` only when:

- Foundation Validation has passed.
- The PR remains inside the declared task scope.
- No protected files were changed.
- No policy violation was detected.
- The PR references the related GitHub issue.
- The PR includes validation evidence.

## Current Required Check

The current required check is:

```text
Foundation Validation / validate-foundation
```

This check is produced by:

```text
.github/workflows/foundation-validation.yml
```

## Future Required Checks

Future versions may add:

- contract validation
- policy validation
- Codex review
- Claude Code execution report validation
- security scan
- dependency scan

## Issue Reference

This policy was introduced for:

```text
GitHub issue #5
```
