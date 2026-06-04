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
  -MaxBudgetUsd 2.00
```

The command reads one executor packet and writes one runtime launch plan.

It does not launch Claude Code, launch Antigravity, run shell commands, call GitHub, install dependencies, touch secrets, or deploy anything.

When `-MaxBudgetUsd` is omitted, SpecBridge uses the bounded default `2.00`.
Operators may still pass an explicit budget greater than `0` and no more than
`10`.

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

Current launch plan evidence includes:

```text
.specbridge/runtime-launches/issue-063-prepare-runtime-launch-plans.runtime-launch.json
.specbridge/runtime-launches/issue-069-fresh-executor-source-run.runtime-launch.json
.specbridge/runtime-launches/issue-071-claude-implementation.runtime-launch.json
.specbridge/runtime-launches/issue-071-claude-audit.runtime-launch.json
```

The issue 069 launch plan was generated from:

```text
.specbridge/executor-packets/issue-069-fresh-executor-source-run-claude-source.executor-packet.json
```

The issue 071 launch plans were generated from two executor packets derived from one governed handoff input:

```text
.specbridge/executor-packets/issue-071-serious-autonomous-test-loop-claude-implementation.executor-packet.json
.specbridge/executor-packets/issue-071-serious-autonomous-test-loop-claude-audit.executor-packet.json
```

## Next Step

Runtime-run, runtime-result, runtime-summary, and autonomy metrics evidence now use launch plans as source inputs. The next runtime expansion should run a small real feature through the same multi-executor loop.
