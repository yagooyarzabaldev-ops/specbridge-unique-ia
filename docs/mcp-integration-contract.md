# MCP Integration Contract Standard

## Purpose

This document defines the MCP integration contract standard for SpecBridge.

The purpose is to describe how Model Context Protocol servers, tools, and resources should be introduced before any real MCP server is implemented.

## Principle

SpecBridge must not expose vague tools to Claude Code or future agents.

Every MCP tool or resource must have a clear contract, scope, input shape, output shape, error shape, and safety boundary.

## Project vs User Scope

Project-scoped MCP configuration is shared through the repository.

Example file:

```text
.mcp.example.json
```

User-scoped MCP configuration is personal and must not be committed.

Example location:

```text
~/.claude.json
```

## Credential Handling

Credentials must not be committed.

MCP examples may reference environment variables only.

Allowed example pattern:

```text
${GITHUB_TOKEN}
${SPECBRIDGE_API_TOKEN}
```

Blocked patterns:

- literal tokens
- private keys
- passwords
- production credentials
- copied `.env` values

## MCP Tool Contract Requirements

Every MCP tool must define:

- tool name
- purpose
- owner system
- allowed caller
- input schema
- output schema
- side effects
- idempotency behavior
- retry behavior
- permission model
- audit fields
- error categories
- stop conditions

## Tool Description Quality

Tool descriptions must explain:

- what the tool does
- when to use it
- when not to use it
- required inputs
- optional inputs
- output fields
- edge cases
- similar tools and boundaries

Minimal descriptions are not acceptable.

## MCP Resource Contract Requirements

Every MCP resource must define:

- resource name
- purpose
- URI pattern
- content type
- refresh behavior
- source of truth
- permission model
- data sensitivity
- expected consumers
- limitations

Resources should expose catalogs, summaries, manifests, schemas, and reference material.

Resources should reduce exploratory tool calls.

## Structured Error Response Standard

MCP tools must return structured errors.

Required shape:

```text
isError: true
errorCategory: transient | validation | permission | business
isRetryable: true | false
message: human-readable summary
attemptedAction: optional action description
partialResult: optional partial data
recoveryHint: optional next step
```

## Error Categories

### transient

Temporary failure such as timeout or service unavailable.

Expected behavior:

- retry only when `isRetryable` is true
- include retry hint when possible

### validation

Invalid or incomplete input.

Expected behavior:

- do not retry unchanged input
- request corrected input or revise contract

### permission

Caller lacks required access.

Expected behavior:

- do not retry blindly
- escalate to human or configuration step

### business

Request violates business or policy rule.

Expected behavior:

- do not retry
- explain policy boundary
- redirect to safe workflow

## Retry Policy

Agents must not infer retryability from natural language.

Retry behavior must be derived from structured fields.

```text
isRetryable: true | false
```

## Side Effects

Any MCP tool with side effects must declare them explicitly.

Examples:

- creates issue
- updates pull request
- changes repository settings
- writes files
- starts workflow
- posts comment

Tools with side effects must include idempotency guidance.

## Stop Conditions

MCP execution must stop if:

- secrets are required
- permission error blocks safe execution
- blocked scope must be modified
- destructive operation is requested
- production state would change without authorization
- tool contract is incomplete
- output cannot be validated

## Current Status

SpecBridge does not yet define a real MCP server.

This document defines the contract standard only.

Implementation remains blocked until MCP tool/resource contracts are stable and validation exists.
