# Standard Loop V1 Feature Pilot

## Purpose

The first real feature pilot for Standard Loop v1 is the `standard-loop-status`
CLI command.

The feature is intentionally small but operational: it reports whether the
repository contains the files required to run the standard loop.

## Command

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 standard-loop-status
```

## Behavior

The command reports:

- current branch and head
- template count
- schema count
- validator count
- CI workflow count
- latest contract, scope, runtime, metrics, audit packet, and ChatGPT audit paths
- missing required Standard Loop v1 paths
- CI security boundary statement

The command exits with:

- `0` when all required standard paths exist
- `1` when any required standard path is missing

## Why This Is The Pilot

This is a real behavior change because it gives operators and future agents a
single deterministic readiness signal for the standard loop.

It is safe as the first pilot because it:

- reads repository files only
- does not launch Claude Code
- does not call GitHub
- does not touch secrets
- does not modify CI/CD workflows
- does not deploy

## Validation

The feature is covered by:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/test-specbridge-cli.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 validate -Profile standard
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
```

## Completion Evidence

The feature is complete when:

- `standard-loop-status` returns `ok: true`
- template validation passes
- schema validation passes
- CI authority validation passes
- runtime execution validation passes
- local standard validation passes
- GitHub CI passes before merge
