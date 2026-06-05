# SpecBridge Runtime Launch Preflight

## Purpose

Runtime launch preflight is a deterministic repository check for one or more prepared runtime launch plans.

It is designed to run before any future operator-controlled live launch. It reads launch artifacts, confirms the required slices are present, checks that write scopes do not overlap, verifies the budget and tool limits, and confirms every launch remains inside the plan-only execution policy boundary.

The command does not launch Claude Code, launch Antigravity, execute shell commands, call GitHub, install dependencies, access secrets, touch production, or deploy.

## Command

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 preflight-runtime-launches `
  -InputPath ".specbridge/runtime-launches/issue-097-status.runtime-launch.json,.specbridge/runtime-launches/issue-097-tests.runtime-launch.json,.specbridge/runtime-launches/issue-097-docs.runtime-launch.json" `
  -RequiredSlice status,tests,docs `
  -AllowedTool Read,Write,Edit `
  -MaxBudgetUsd 2.00 `
  -OutputPath .specbridge/preflights/issue-099-runtime-launch-preflight.runtime-preflight.json `
  -Force
```

`InputPath` accepts either a comma-separated list of runtime launch files or a directory under `.specbridge/runtime-launches`.

`RequiredSlice` is optional. When provided, every declared slice id must appear exactly once.

`AllowedTool` is the preflight tool allow-list. Every launch plan's `allowed_tools` must be a subset of that list.

`MaxBudgetUsd` is the per-launch preflight budget ceiling.

## Output

The command writes deterministic JSON to stdout and optionally to `.specbridge/preflights/*.runtime-preflight.json`.

The output records:

- loaded launch paths
- loaded launch summaries
- required slice ids
- missing or duplicate slices
- non-overlap result
- budget result
- tools result
- execution policy result
- blockers
- source files
- output path

`ok=true` means the preflight found no blockers. It does not mean the live execution has run or that merge is allowed.

## Failure Conditions

The command fails when:

- a required launch file is missing or invalid
- a required slice is missing
- a slice appears more than once
- any `exclusive_write` path overlaps another launch plan
- any launch budget exceeds the configured limit
- any launch uses a tool outside the configured allow-list
- any plan-only execution policy boolean is missing, non-boolean, or not `false`

## Validation

Runtime preflight artifacts are validated by:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-preflights.ps1
```

The validator requires a valid file-backed preflight artifact and blocks approved output with missing slices, duplicate slices, failed non-overlap checks, failed budget checks, failed tool checks, failed execution policy checks, or non-empty blockers.
