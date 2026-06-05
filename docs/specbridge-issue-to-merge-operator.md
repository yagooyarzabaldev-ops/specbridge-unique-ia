# SpecBridge Issue-to-Merge Operator

## Purpose

`issue-to-merge-plan` is the governed operator view for moving one SpecBridge task from issue intake to policy-gated merge.

It exists to reduce manual orchestration while preserving the repository rules that make SpecBridge auditable.

## Command

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 issue-to-merge-plan `
  -TaskId issue-109-governed-issue-to-merge-operator `
  -RelatedIssue https://github.com/yagooyarzabaldev-ops/specbridge/issues/109
```

Optional file-backed artifact:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 issue-to-merge-plan `
  -TaskId issue-109-governed-issue-to-merge-operator `
  -RelatedIssue https://github.com/yagooyarzabaldev-ops/specbridge/issues/109 `
  -OutputPath .specbridge/issue-to-merge-runs/issue-109-governed-issue-to-merge-operator.issue-to-merge-run.json `
  -Force
```

## Behavior

The command emits deterministic JSON with:

- `command: issue-to-merge-plan`
- `mode: plan_only`
- task id, title, goal, issue reference, repository URL, base branch, recommended branch, current branch, and head
- evidence paths for contract, scope, final report, audit packet, ChatGPT/Codex audit, issue-to-merge run, and Standard Loop run
- ordered issue-to-merge phases
- required local gates
- required GitHub gates
- merge conditions
- post-merge memory closure requirements
- policy boundaries
- command boundary
- optional output artifact path

## Phases

The operator plan records these phases:

1. GitHub issue intake
2. Execution contract, scope, report, and audit package
3. Local validation gates
4. Pull request creation or update
5. GitHub CI and review gates
6. Policy-gated merge
7. Post-merge repository memory closure

Each phase records required evidence, the gate that must pass, whether repository files are expected to be written, and whether the command calls GitHub.

## Boundary

The first implementation is intentionally plan-only.

The command does not:

- create GitHub issues
- open pull requests
- wait for CI
- merge pull requests
- launch Claude Code
- launch Antigravity
- install dependencies
- change workflow files
- deploy

The only write it can perform is the explicitly requested `-OutputPath` under:

```text
.specbridge/issue-to-merge-runs/*.issue-to-merge-run.json
```

## Merge Conditions

The plan records these merge conditions:

- CI passed
- tests passed
- no policy violation
- no protected files changed
- ChatGPT/Codex audit approved
- branch mergeable
- deployment not requested

## Completion Standard

The command returns exit code `0` when a `TaskId` is provided and the plan is emitted or written.

The command returns exit code `1` when required inputs are missing, including a missing `TaskId`.

## Validation

The command is covered by:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/test-specbridge-cli.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
```
