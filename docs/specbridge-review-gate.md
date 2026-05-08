# SpecBridge Review Gate

## Purpose

The SpecBridge Review Gate is an active deterministic pull request gate.

It checks pull request changes for governance violations before live agent execution is introduced.

## Current Boundary

This gate is intentionally deterministic and does not activate:

- Claude Code execution
- Codex review
- MCP servers
- production secrets
- deployment automation
- application runtime code

## Review Rules

The gate fails when a pull request changes blocked paths such as:

- `.env`
- `.env.*`
- `secrets/**`
- `infra/prod/**`
- runtime/application source paths
- database implementation paths

The gate also fails when workflow changes introduce:

- live Claude execution workflow activation patterns
- live Codex review workflow activation patterns
- direct use of GitHub Actions secrets during this foundation phase

## Local Command

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/validate-review-gate.ps1
```

## CI Behavior

The workflow `.github/workflows/specbridge-review-gate.yml` runs on pull requests targeting `main`.

## Role In The SpecBridge Loop

The review gate is the first active PR-level guard beyond foundation validation.

It is not an AI reviewer yet. It is a deterministic safety rail before AI review is introduced.
