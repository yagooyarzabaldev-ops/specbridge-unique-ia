# SpecBridge Runtime Launch Plans

## Purpose

Runtime launch plans are deterministic repository artifacts that prepare a bounded Claude Code runtime invocation from an executor packet.

They close the gap between a handoff packet and an operator or future runner launching Claude Code. The plan records the allowed command shape, tool limits, budget, prompt sections, write scope, read-only context, validations, and stop conditions without executing Claude Code.

## Command

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 prepare-runtime-launch `
  -InputPath .specbridge/executor-packets/<packet>.executor-packet.json `
  -OutputPath .specbridge/runtime-launches/<task>.runtime-launch.json `
  -AllowedTool Read,Write `
  -PermissionMode acceptEdits `
  -MaxBudgetUsd 0.25
```

The command reads one executor packet and writes one runtime launch plan.

It does not launch Claude Code, launch Antigravity, run shell commands, call GitHub, install dependencies, touch secrets, or deploy anything.

## Artifact

Runtime launch plans live under:

```text
.specbridge/runtime-launches/*.runtime-launch.json
```

Each plan records:

- source executor packet path
- task id
- packet id
- slice id
- branch name
- execution contract path
- final report path
- exclusive write paths
- read-only context paths
- required validations
- allowed Claude Code tools
- permission mode
- max budget
- command summary
- prompt sections
- stop conditions
- planning-only execution policy
- launch status
- source files

## Validation

Runtime launch plans are validated by:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-launches.ps1
```

The validator requires:

- repository-relative paths
- a source executor packet under `.specbridge/executor-packets/`
- an execution contract under `.specbridge/contracts/`
- a final report path under `.specbridge/reports/`
- non-empty write scope, read-only context, validations, prompt sections, and stop conditions
- allowed tools limited to `Read`, `Write`, or `Edit`
- `Read` and `Write` present for the default runtime launch plan
- max budget greater than `0` and no more than `10`
- command summary in non-interactive Claude print mode
- planning-only execution policy booleans set to false
- no dangerous permission bypass wording

## Runtime Boundary

Runtime launch plans are preparation artifacts only.

They do not certify that the executor ran, that tests passed, or that merge is allowed. Runtime result artifacts capture executor exit code, written files, validation results, policy result, and completion status after a bounded run.

## Current Evidence

The first launch plan is:

```text
.specbridge/runtime-launches/issue-063-prepare-runtime-launch-plans.runtime-launch.json
```

It was generated from:

```text
.specbridge/executor-packets/issue-061-controlled-antigravity-runtime-launch-claude-runtime.executor-packet.json
```

## Next Step

Runtime result recording and runtime summaries now use launch plans as evidence inputs.

The next runtime task should create fresh executor output from a bounded source implementation task, then record and summarize that result through the same launch, result, audit, CI, and merge gates.
