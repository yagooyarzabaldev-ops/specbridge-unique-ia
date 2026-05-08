# SpecBridge PR Review Report Generator

## Purpose

This document defines the deterministic PR review report generator.

The generator is the last non-invasive step before live Claude/Codex review automation. It produces a machine-readable review report artifact on pull requests without calling external AI services.

## Boundary

The generator does not use:

- secrets
- Claude Code
- Codex
- MCP servers
- deployment automation
- runtime application code

It only reads changed file names and produces a JSON artifact conforming to the active PR review report schema.

## Local Command

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/generate-pr-review-report.ps1
powershell -ExecutionPolicy Bypass -File ./scripts/validate-pr-review-reports.ps1 -ReportsPath .specbridge/generated-review-reports
```

## Workflow

The active workflow is:

```text
.github/workflows/specbridge-pr-review-report.yml
```

It runs on pull requests targeting `main`.

## Generated Artifact

The workflow uploads:

```text
specbridge-pr-review-report
```

The uploaded artifact contains the generated `.review-report.json` file.

## Role In The SpecBridge Progression

This generator proves that SpecBridge can produce review artifacts in CI before the reviewer is replaced by live Claude/Codex.
