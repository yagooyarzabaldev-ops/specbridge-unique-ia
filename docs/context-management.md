# Context Management Standard

## Purpose

This document defines how SpecBridge preserves important context across long-running agent workflows.

## Principle

Important execution facts must not live only in conversational memory.

Critical facts must be persisted in repository files or structured state artifacts.

## Context Layers

SpecBridge uses these context layers:

```text
.specbridge/context/CASE_FACTS.md
.specbridge/context/SOURCE_MANIFEST.md
.specbridge/context/EXECUTION_STATE.md
.specbridge/context/HANDOFF_SUMMARY.md
```

## Case Facts

Case facts preserve durable task facts.

Examples:

- issue number
- contract id
- branch name
- validation commands
- validation results
- risk level
- merge status

## Source Manifest

Source manifests preserve provenance.

Examples:

- source file path
- source URL
- document title
- commit SHA
- PR number
- issue number
- relevant excerpt

## Execution State

Execution state preserves workflow progress.

Examples:

- current phase
- completed validations
- blocked validations
- unresolved risks
- next action

## Handoff Summary

Handoff summaries preserve what a new agent or human needs to continue safely.

They must include:

- goal
- current state
- changed files
- validations executed
- blockers
- recommended next step

## Stale Context Rule

When prior tool results are stale, start a fresh session with structured summaries instead of relying on old conversational state.

## Lost-in-the-Middle Mitigation

Important summaries should be placed near the top of long context packages.

Detailed evidence should be grouped under explicit headings.

## Stop Conditions

Stop if critical facts are missing, contradictory, or only available in unverified chat memory.
