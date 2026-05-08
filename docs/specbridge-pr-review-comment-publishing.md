# SpecBridge PR Review Comment Publishing

## Purpose

SpecBridge PR review comment publishing makes deterministic review reports visible inside the pull request conversation.

This is not live Claude/Codex review. It is a CI-generated Markdown rendering of the machine-readable review report.

## Boundary

The publisher uses the GitHub Actions token only.

It does not use:

- user secrets
- Claude Code
- Codex
- MCP servers
- deployment automation
- runtime application code

## Scripts

Render the Markdown comment:

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/render-pr-review-comment.ps1
```

Publish the comment inside GitHub Actions:

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/publish-pr-review-comment.ps1
```

## Idempotency

The rendered comment contains this marker:

```text
<!-- specbridge-pr-review-report -->
```

The publisher updates the existing comment when it finds that marker. Otherwise, it creates a new comment.

## Workflow

The active workflow is:

```text
.github/workflows/specbridge-pr-review-report.yml
```

It:

1. Generates a deterministic review report.
2. Validates the generated report.
3. Renders a Markdown comment.
4. Creates or updates the PR comment.
5. Uploads the JSON and Markdown artifacts.

## Role In The SpecBridge Progression

This proves visible PR review delivery before replacing the deterministic generator with a live AI reviewer.
