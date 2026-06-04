# SpecBridge Standard Loop Orchestrator

## Purpose

`standard-loop-orchestrate` is the first deterministic one-command view of the
SpecBridge Standard Loop.

It gives operators and agents a repository-backed issue-to-merge sequence without
depending on chat memory.

## Command

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 standard-loop-orchestrate
```

Optional file-backed artifact:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 standard-loop-orchestrate `
  -TaskId issue-093-standard-loop-orchestrator `
  -OutputPath .specbridge/standard-loop-runs/issue-093-standard-loop-orchestrator.standard-loop-run.json `
  -Force
```

## Behavior

The command emits deterministic JSON with:

- `command: standard-loop-orchestrate`
- `mode: plan_only`
- current branch and head
- current repository phase from `.specbridge/context/CURRENT_GOAL.md`
- next recommended action from `.specbridge/context/CURRENT_GOAL.md`
- the ordered Standard Loop phases
- required local and GitHub gates
- latest known repository artifacts
- required docs, templates, schemas, validators, and CI workflow paths
- missing required paths
- policy boundaries
- optional output artifact path

## Boundary

The command does not:

- launch Claude Code
- launch Antigravity
- call GitHub
- install dependencies
- deploy
- change product code
- change workflow files

The only write it can perform is the explicitly requested `-OutputPath` under:

```text
.specbridge/standard-loop-runs/*.standard-loop-run.json
```

## Completion Standard

The command returns exit code `0` when required Standard Loop paths exist.

It returns exit code `1` if required docs, templates, schemas, validators, or CI
workflow paths are missing.

## Validation

The command is covered by:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/test-specbridge-cli.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
```
