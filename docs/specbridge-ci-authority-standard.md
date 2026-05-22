# SpecBridge CI Authority Standard

## Purpose

CI authority defines when local evidence is allowed to advance to merge.

Local validation can prepare a task for review. GitHub CI is the external merge
authority. A task is not complete until the pull request checks pass.

## Current GitHub CI Authority

Standard Loop v1 depends on these existing workflows:

- `.github/workflows/foundation-validation.yml`
- `.github/workflows/specbridge-review-gate.yml`
- `.github/workflows/specbridge-pr-review-report.yml`
- `.github/workflows/claude-review-non-blocking.yml`

These workflows are read-only for this standardization package.

## Required Local Gates

Before push:

- standard validation profile
- smoke validation
- CLI tests
- negative validation tests
- schema validation
- template validation
- runtime execution validation
- security gate
- review gate
- audit packet validation
- ChatGPT audit validation
- git diff whitespace check

## Required GitHub Gates

Before merge:

- GitHub CI passes
- SpecBridge Review Gate passes
- SpecBridge PR Review Report passes
- Foundation Validation passes
- Claude Review Non Blocking completes successfully or remains non-blocking by policy

## Security Boundary

`.github/workflows/**` is a CI/CD security boundary. This package does not modify
workflow files. Any future change to workflow permissions, triggers, secrets, or
merge behavior requires a dedicated execution contract and explicit security
review.

## Validation

CI authority is validated by:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-standard-ci-authority.ps1
```

The validator confirms that the standard documents exist, mention CI authority,
GitHub CI, security gate, and review gate, and that the required existing workflow
files are present.
