# SpecBridge CI Authority Standard

## Purpose

CI authority defines when local evidence is allowed to advance to merge.

Local validation can prepare a task for review. GitHub CI is the external merge
authority. A task is not complete until the pull request checks pass.

## Current GitHub CI Authority

Provider-neutral deterministic CI for Unique IA depends on these workflows:

- `.github/workflows/unique-ai-ci.yml`
- `.github/workflows/foundation-validation.yml`
- `.github/workflows/specbridge-review-gate.yml`
- `.github/workflows/specbridge-pr-review-report.yml`

These workflows are read-only except under an active, unexpired workflow-change
authorization entry in `.specbridge/policies/workflow-change-authorizations.json`.

## Required Local Gates

Before push:

- standard validation profile
- contract validation
- scope validation
- final report validation
- audit packet validation
- ChatGPT audit validation
- CI authority validation
- git diff whitespace check
- security gate
- review gate

## Required GitHub Gates

Before merge:

- GitHub CI passes (unique-ai-ci check must pass)
- Foundation Validation passes
- SpecBridge Review Gate passes
- SpecBridge PR Review Report passes

## Security Boundary

`.github/workflows/**` is a CI/CD security boundary. Workflow changes are
blocked by default. Any change requires an unexpired entry in the
workflow-change authorization registry, a dedicated execution contract with
`risk_level: high`, and explicit human operator authorization.

Provider-specific AI actions (anthropics/, openai/, codex actions) and
provider API-key secrets (ANTHROPIC_API_KEY, OPENAI_API_KEY) are not permitted
in any active workflow. Deterministic, provider-neutral CI is the Unique IA
security gate and review gate standard.

## Validation

CI authority is validated by:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-standard-ci-authority.ps1
```

The validator confirms that the standard documents exist, mention CI authority,
GitHub CI, security gate, and review gate, and that the required existing workflow
files are present.
