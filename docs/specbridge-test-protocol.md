# SpecBridge Test Protocol

## Purpose

This protocol verifies that SpecBridge can process a controlled change through the intended foundation loop:

1. GitHub issue.
2. Execution contract.
3. Branch-scoped change.
4. Local deterministic validation.
5. Pull request.
6. Required CI validation.
7. Human-controlled merge.

## Current Test Boundary

This test does not activate real Claude Code execution, Codex review, MCP servers, production secrets, deployment automation, or application runtime code.

## Local Smoke Command

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
```

## Required Result

The smoke runner must pass:

- foundation validation
- contract validation
- schema validation

## CI Requirement

The GitHub Actions workflow `Foundation Validation` must pass before merge.

## Failure Handling

If any validation fails, stop and inspect the exact failing validator output before modifying files.

## Completion Definition

SpecBridge is considered minimally testable when this protocol, the smoke runner, and the CI smoke step are merged into `main`.
