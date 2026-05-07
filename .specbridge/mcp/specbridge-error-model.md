# SpecBridge MCP Error Model

## Purpose

Define the standard MCP error shape.

## Required Shape

```text
isError: true
errorCategory: transient | validation | permission | business
isRetryable: true | false
message: human-readable summary
attemptedAction: optional action description
partialResult: optional partial data
recoveryHint: optional next step
```

## Rule

Agents must not infer retryability from prose.
