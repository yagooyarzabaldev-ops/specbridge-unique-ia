# Claude Code Configuration Standard

## Purpose

This document defines the first project-scoped Claude Code configuration standard for SpecBridge.

The goal is to make Claude Code execution predictable before any autonomous execution workflow is enabled.

## Configuration Principle

Claude Code must operate from repository-governed context, not from ad hoc chat memory.

Project-scoped configuration should be version-controlled so team behavior is repeatable.

## Project-Scoped Layout

SpecBridge uses this Claude Code layout:

```text
.claude/rules/
.claude/commands/
.claude/skills/
```

## Rules

Rules define project behavior that Claude Code should apply when working in this repository.

Initial rules:

```text
.claude/rules/specbridge-foundation.md
```

Rules should remain concise and operational.

Rules must not duplicate every detail from `SPECBRIDGE.md`, `AGENTS.md`, or `CLAUDE.md`. They should point Claude Code toward the source of truth and define execution boundaries.

## Commands

Project commands provide repeatable task entry points.

Initial commands:

```text
.claude/commands/specbridge-validate.md
.claude/commands/specbridge-report.md
```

Commands should avoid destructive operations.

Commands should prefer validation, reporting, and review workflows before autonomous implementation.

## Skills

Skills provide focused workflows for reusable tasks.

Initial skill:

```text
.claude/skills/specbridge-contract-review/SKILL.md
```

Skills should use frontmatter to define behavior and tool boundaries.

Recommended skill properties:

```text
context: fork
allowed-tools: Read, Grep, Glob
argument-hint: path to execution contract or pull request context
```

## Plan Mode vs Direct Execution

Claude Code should use plan mode for:

- multi-file changes
- architectural decisions
- workflow design
- policy-sensitive work
- unclear acceptance criteria

Claude Code may use direct execution for:

- documentation-only changes
- validation script updates with clear scope
- small corrections with objective acceptance criteria

## Stop Conditions

Claude Code must stop if:

- blocked scope must be modified
- secrets are required
- production configuration is required
- destructive operations are required
- acceptance criteria are contradictory
- validation fails repeatedly without a safe fix
- the execution contract is missing required sections

## Validation Commands

Claude Code should use these commands for foundation work:

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/validate-foundation.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
```

## Current Status

This configuration standard introduces Claude Code project structure only.

It does not enable autonomous Claude Code execution yet.

Autonomous execution remains blocked until execution workflow, review workflow, and policy gates are defined.