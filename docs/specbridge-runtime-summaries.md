# SpecBridge Runtime Summaries

## Purpose

Runtime summaries are deterministic repository artifacts that connect a runtime launch plan with a runtime result.

They are the first source-backed runtime implementation slice after launch planning and result recording. The local CLI now reads both evidence layers, verifies that they describe the same bounded executor chain, and writes a compact summary for review and later policy gates.

## Command

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 summarize-runtime `
  -InputPath .specbridge/runtime-launches/<task>.runtime-launch.json `
  -EvidencePath .specbridge/runtime-results/<task>.runtime-result.json `
  -OutputPath .specbridge/runtime-summaries/<task>.runtime-summary.json
```

The command reads one runtime launch plan and one runtime result artifact.

It does not launch Claude Code, launch Antigravity, run shell commands, call GitHub, install dependencies, touch secrets, or deploy anything.

## Artifact

Runtime summaries live under:

```text
.specbridge/runtime-summaries/*.runtime-summary.json
```

Each summary records:

- runtime launch path
- runtime result path
- launch id
- task id
- packet id
- slice id
- branch name
- completion status
- runtime status
- result status
- validation totals
- policy result
- merge readiness
- blockers
- execution policy
- source files

## Validation

Runtime summaries are validated by:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-runtime-summaries.ps1
```

The validator requires:

- repository-relative paths
- an existing source runtime launch under `.specbridge/runtime-launches/`
- an existing source runtime result under `.specbridge/runtime-results/`
- matching launch id, task id, packet id, slice id, and branch name across launch, result, and summary
- `runtime_result_path.source_runtime_launch_path` matching the summary launch path
- validation totals matching the runtime result validation records
- blocked summaries to include blockers
- ready summaries to have no blockers
- execution policy booleans set to false
- source files that include the launch and result paths

## Merge Readiness

`merge_readiness` is not a merge decision by itself.

It is set to `ready_for_policy_gates` only when:

- runtime status is `succeeded`
- result status is `recorded`
- completion status is `complete`
- every runtime validation result passed
- policy result is present

A later merge still requires CI, security gate, review gate, audit packet validation, ChatGPT/Codex audit, scope validation, and active policy approval.

## Current Evidence

Current runtime summary evidence includes:

```text
.specbridge/runtime-summaries/issue-067-source-backed-runtime-slice.runtime-summary.json
.specbridge/runtime-summaries/issue-069-fresh-executor-source-run.runtime-summary.json
.specbridge/runtime-summaries/issue-071-claude-implementation.runtime-summary.json
.specbridge/runtime-summaries/issue-071-claude-audit.runtime-summary.json
```

The issue 069 summary links:

```text
.specbridge/runtime-launches/issue-069-fresh-executor-source-run.runtime-launch.json
.specbridge/runtime-results/issue-069-fresh-executor-source-run.runtime-result.json
```

The issue 071 summaries link both bounded executor slices to `ready_for_policy_gates` evidence before autonomy metrics and ChatGPT/Codex audit.

## Next Step

The next runtime expansion should use the multi-executor chain for a small real feature implementation and keep coordinator integration blocked until every summary is ready for policy gates.
