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

## Safe Pilot

Issue 111 is the first safe pilot of the operator after issue 109.

The pilot runs:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 issue-to-merge-plan `
  -TaskId issue-111-issue-to-merge-operator-pilot `
  -Title "Pilot issue-to-merge operator" `
  -Goal "Pilot the deterministic plan-only SpecBridge issue-to-merge operator with a safe documentation and evidence task before any future GitHub-mutating operator mode." `
  -RelatedIssue https://github.com/yagooyarzabaldev-ops/specbridge/issues/111 `
  -OutputPath .specbridge/issue-to-merge-runs/issue-111-issue-to-merge-operator-pilot.issue-to-merge-run.json `
  -Force
```

The pilot result is intentionally documentation and evidence only:

- one issue-backed execution contract
- one scope manifest
- one file-backed issue-to-merge run artifact
- one final report
- one audit packet
- one ChatGPT/Codex audit
- README and current-goal memory updates

This pilot does not authorize a GitHub-mutating operator mode. Creating issues, opening PRs, waiting on CI, merging, and post-merge issue closure remain actions performed by the surrounding governed process, not by `issue-to-merge-plan`.

## Bounded GitHub Mutation Mode

Issue 113 adds `issue-to-merge-github`, the first bounded GitHub mutation operator mode.

The command is dry-run by default:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 issue-to-merge-github `
  -TaskId issue-113-bounded-github-mutation-operator `
  -RelatedIssue https://github.com/yagooyarzabaldev-ops/specbridge/issues/113 `
  -OutputPath .specbridge/issue-to-merge-runs/issue-113-bounded-github-mutation-operator.github-mutation-run.json `
  -Force
```

The dry-run artifact records explicit connector actions for:

- creating or verifying the issue
- opening or updating the PR
- waiting for required GitHub checks
- merging only after policy gates pass
- closing the completed issue
- updating post-merge repository memory

Apply mode is not implicit. It requires `-MutationMode apply`, `-Force`, `-ConfirmGithubMutation`, and a declared `.specbridge/github-evidence/*.github-mutation-evidence.json` file proving local gates, security gate, review gate, GitHub CI, ChatGPT/Codex audit, protected-file status, and no-deployment status.

This keeps GitHub mutation as a governed connector action envelope instead of an unrestricted local shell action.

## GitHub Evidence Loop Pilot

Issue 115 is the first governed evidence loop after bounded GitHub mutation mode.

The pilot runs `issue-to-merge-github` in dry-run mode for issue 115 and writes:

```text
.specbridge/issue-to-merge-runs/issue-115-github-evidence-loop.github-mutation-run.json
```

The pilot then records a bounded comparison artifact:

```text
.specbridge/github-evidence/issue-115-github-evidence-loop.github-mutation-evidence.json
```

That artifact compares the dry-run connector envelope with the real GitHub lifecycle evidence that can exist at each phase: issue intake, branch and PR, required CI checks, policy-gated merge, issue closure, and repository memory. Pre-merge repository files must not claim merge or closure facts before GitHub records them.

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
