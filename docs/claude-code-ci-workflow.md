# Claude Code CI Workflow

## Purpose

This document defines how Claude Code should participate in CI review workflows for SpecBridge.

This is a design standard only. It does not activate a real Claude Code workflow.

## Principle

Claude Code in CI must be non-interactive, structured, independently scoped, and review-oriented.

Claude Code must not hang waiting for user input.

## Non-Interactive Mode

Claude Code CI usage must use non-interactive execution.

Expected pattern:

```text
claude -p
```

or:

```text
claude --print
```

## Structured Output

Claude Code review output must be machine-readable.

Expected output format:

```text
json
```

The output must conform to:

```text
.specbridge/schemas/claude-review-output.schema.json
```

## Independent Review Instance

Claude Code review must run as an independent review instance.

The same session that generated code should not be the only reviewer of that code.

## Review Scope

Allowed review categories:

- correctness
- security
- test coverage
- contract compliance
- policy violation
- regression risk
- maintainability risk

Disallowed review categories as blockers:

- personal style preference
- cosmetic formatting without functional impact
- speculative architecture rewrites
- unrelated refactors

## Severity Rules

Severity must be explicit.

Allowed severities:

- info
- low
- medium
- high
- critical

Only high or critical findings should block merge by default.

Medium findings may block only when they violate an explicit execution contract.

## False Positive Reduction

Review prompts must define what to report and what to ignore.

Claude Code should not report vague findings without evidence.

Every finding must include:

- file path
- line or section when available
- evidence
- reason
- recommended fix

## Rerun Behavior

When review runs again after new commits, it should report:

- new findings
- still-unresolved findings

It should avoid duplicate findings already addressed or already reported unchanged.

## Current Status

This document defines review workflow expectations only.

Actual Claude Code CI execution remains disabled until a workflow is intentionally activated.
