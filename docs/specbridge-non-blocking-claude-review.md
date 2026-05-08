# SpecBridge Non-Blocking Claude Review Workflow

## Purpose

This document defines the first live Claude review workflow for SpecBridge.

The workflow is intentionally non-blocking and review-only.

## Official Integration Basis

The workflow uses the Claude Code GitHub Action v1 pattern.

It requires `ANTHROPIC_API_KEY` as a GitHub Actions repository secret when direct Anthropic API authentication is used.

## Boundary

The workflow may review pull requests and leave feedback.

It must not:

- push commits
- merge pull requests
- edit files
- deploy
- request production secrets
- implement MCP servers
- modify runtime application code

## Fallback Behavior

If `ANTHROPIC_API_KEY` is not configured, the workflow records a non-blocking skip result in the GitHub Actions job summary.

## Permissions

The workflow uses:

```yaml
contents: read
pull-requests: write
issues: write
```

It intentionally does not request `contents: write`.

## Validation

The workflow is checked by:

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/validate-claude-review-workflow.ps1
```

## Role In SpecBridge

This is the first transition from deterministic review reporting to live AI-assisted PR review.

The deterministic gates remain active and required.
