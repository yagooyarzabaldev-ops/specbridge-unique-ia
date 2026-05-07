# MCP Tool Contract Template

## Tool Metadata

- tool_name:
- owner_system:
- version:
- status:
- risk_level:
- has_side_effects:

## Purpose

Describe exactly what this tool does.

## When To Use

Define the situations where the agent should call this tool.

## When Not To Use

Define boundaries and similar tools that should be used instead.

## Input Schema

```json
{}
```

## Output Schema

```json
{}
```

## Side Effects

Declare whether the tool changes state.

Examples:

- none
- creates issue
- updates pull request
- writes file
- changes repository setting

## Idempotency

Define whether repeated calls are safe.

## Permission Model

Define required permissions.

## Retry Policy

Define when the tool may be retried.

## Structured Error Response

Errors must use this shape:

```text
isError: true
errorCategory: transient | validation | permission | business
isRetryable: true | false
message: human-readable summary
attemptedAction: optional action description
partialResult: optional partial data
recoveryHint: optional next step
```

## Audit Fields

Define fields that must be logged for traceability.

## Stop Conditions

Define conditions where the agent must stop instead of retrying or improvising.

## Examples

Provide examples of valid calls and invalid calls.
