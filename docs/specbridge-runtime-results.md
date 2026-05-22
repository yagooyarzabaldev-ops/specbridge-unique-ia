# SpecBridge Runtime Results

## Purpose

Runtime results are deterministic repository artifacts that record the observed outcome of a bounded Claude Code runtime execution.

They close the gap between a runtime launch plan and later audit or merge decisions. A launch plan describes how an executor may run. A runtime result records what evidence exists after that run.

## Command

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 record-runtime-result `
  -InputPath .specbridge/runtime-launches/<task>.runtime-launch.json `
  -EvidencePath .specbridge/runtime-evidence/<executor-output>.md `
  -OutputPath .specbridge/runtime-results/<task>.runtime-result.json `
  -RuntimeExitCode 0 `
  -WrittenFile .specbridge/runtime-evidence/<executor-output>.md `
  -Validation "executor invocation: passed" `
  -PolicyResult "Passed." `
  -CompletionStatus complete
```

The command reads one runtime launch plan and one executor evidence file, then writes one runtime result artifact.

It does not launch Claude Code, launch Antigravity, run shell commands, call GitHub, install dependencies, touch secrets, or deploy anything.

## Artifact

Runtime results live under:

```text
.specbridge/runtime-results/*.runtime-result.json
```

Each result records:

- source runtime launch path
- launch id
- task id
- packet id
- slice id
- branch name
- executor evidence path
- exit code
- files written
- validation results
- policy result
- stop conditions
- completion status
- runtime status
- result status
- recording-only execution policy
- source files

## Validation

Runtime results are validated by:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-results.ps1
```

The validator requires:

- repository-relative paths
- a source runtime launch under `.specbridge/runtime-launches/`
- an existing executor evidence file
- an exit code from `0` through `255`
- non-empty files written, validation results, stop conditions, and source files
- executor evidence included in `files_written`
- executor evidence and every written file declared in the source launch plan `exclusive_write`
- launch id, task id, packet id, slice id, and branch name matching the source launch plan
- result status set to `recorded`
- recording-only execution policy booleans set to false

## Runtime Boundary

Runtime results are evidence records only.

They do not certify merge readiness by themselves. A complete task still needs validation evidence, GitHub CI, security gate, review gate, audit packet validation, ChatGPT/Codex audit, and policy-gated merge.

## Current Evidence

Current runtime result evidence includes:

```text
.specbridge/runtime-results/issue-065-record-runtime-results.runtime-result.json
.specbridge/runtime-results/issue-069-fresh-executor-source-run.runtime-result.json
.specbridge/runtime-results/issue-071-claude-implementation.runtime-result.json
.specbridge/runtime-results/issue-071-claude-audit.runtime-result.json
```

The issue 069 result was recorded from:

```text
.specbridge/runtime-launches/issue-069-fresh-executor-source-run.runtime-launch.json
```

and:

```text
.specbridge/runtime-evidence/issue-069-fresh-executor-source-run.executor-output.md
```

The issue 071 results were recorded from the two issue 071 runtime launch plans and their executor output evidence files.

## Next Step

Runtime summaries and autonomy metrics now use launch plans, runtime runs, and runtime results as source-backed evidence. The next runtime task should apply the same chain to a small real feature.
