# SpecBridge Local CLI

## Purpose

The local CLI is the first file-backed SpecBridge runtime surface.

It exposes the existing repository governance loop through deterministic commands that read declared repository paths, write declared artifact paths, avoid network calls by default, and return non-zero exit codes when validation or required inputs fail.

## Invocation

Use the script directly from the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 status
```

When the script is aliased as `specbridge`, the intended command shape is:

```powershell
specbridge status
```

## Commands

| Command | Purpose | Writes files |
| --- | --- | --- |
| `status` | Prints repository status, policy mode, branch, commit, artifact counts, and optionally latest artifact paths as JSON. | No |
| `validate` | Runs deterministic validation profiles. | No |
| `create-contract` | Creates a draft execution contract at a declared contract path. | Yes |
| `create-report` | Creates a final report JSON at a declared report path. | Yes |
| `audit-packet` | Wraps audit packet generation for a declared contract and final report. | Yes |
| `detect-conflicts` | Runs contract scope conflict validation. | No |
| `decompose-task` | Creates a file-backed multi-agent decomposition from a declared JSON input. | Yes |
| `prepare-executors` | Creates Antigravity executor handoff packets from declared slice inputs. | Yes |
| `prepare-runtime-launch` | Creates a bounded runtime launch plan from one executor packet. | Yes |
| `preflight-runtime-launches` | Checks prepared runtime launch plans for required slices, non-overlap, budget, tools, and plan-only policy. | Optional |
| `record-runtime-result` | Records bounded runtime execution evidence from a launch plan and executor output. | Yes |
| `summarize-runtime` | Links one runtime launch plan and one runtime result into a validated runtime summary. | Yes |
| `plan-executor-branches` | Creates one planned executor branch record per executor packet. | Yes |
| `record-github-evidence` | Hydrates a branch plan with declared real GitHub child PR, CI, and ChatGPT/Codex audit evidence. | Yes |
| `coordinate-executors` | Aggregates executor branch evidence into a coordinator orchestration artifact. | Yes |
| `review-gate` | Runs security gate validation and PR review gate validation. | No |

## Validation Profiles

`specbridge validate` supports:

| Profile | Behavior |
| --- | --- |
| `standard` | Runs foundation, contract, scope, schema, final report, audit packet, ChatGPT audit, executor packet, runtime launch, runtime result, runtime summary, branch orchestration, security, review report, Claude workflow, autonomous protocol, and review gate validation. |
| `full` | Runs the standard profile plus negative validation fixtures. |
| `smoke` | Runs `scripts/specbridge-smoke.ps1`. |

The default profile is `standard`.

## Status Latest Artifacts

`status` accepts `-IncludeLatestArtifacts`.

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 status -IncludeLatestArtifacts
```

When enabled, the JSON output includes `latest_artifacts` with the newest known contract, scope, final report, audit packet, ChatGPT audit, runtime launch, runtime preflight, runtime result, and runtime summary paths.

The selection is deterministic: artifact names that begin with `issue-<number>` are ordered by issue number first, then by file name.

## Artifact Commands

`create-contract` requires:

- `TaskId`
- `Title`
- `Goal`
- `RelatedIssue`
- `OutputPath`

`OutputPath` must be under `.specbridge/contracts/` and end with `.execution.md`.

`create-report` requires:

- `Summary`
- at least one `ChangedFile`
- at least one `Validation`
- `PolicyResult`
- `RiskResult`
- `OutputPath`

`OutputPath` must be under `.specbridge/reports/` and end with `.final-report.json`.

`audit-packet` requires:

- `TaskId`
- `ContractPath`
- `ReportPath`

The command delegates to `scripts/generate-audit-packet.ps1` and writes under `.specbridge/audit-packets/` by default.

## Decomposition Input

`decompose-task` expects a JSON file with:

```json
{
  "task_id": "example-task",
  "slices": [
    {
      "id": "agent-a",
      "goal": "Implement one isolated slice.",
      "exclusive_write": ["docs/agent-a.md"]
    }
  ]
}
```

The output must be declared under `.specbridge/decompositions/` and end with `.decomposition.json`.

The CLI rejects duplicate `exclusive_write` paths inside the decomposition.

## Executor Handoff Input

`prepare-executors` expects a JSON file with:

```json
{
  "task_id": "example-task",
  "slices": [
    {
      "id": "agent-a",
      "role": "implementation",
      "goal": "Run one executor contract.",
      "contract_path": ".specbridge/contracts/example.execution.md",
      "final_report_path": ".specbridge/reports/example.final-report.json",
      "exclusive_write": ["docs/agent-a.md"],
      "read_only": ["README.md"],
      "required_validations": ["powershell -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1"]
    }
  ]
}
```

The command writes `.specbridge/executor-packets/*.executor-packet.json` files and rejects duplicate branch names.

Generated packets use `manual_antigravity` launch mode. They prepare the handoff for a separate Antigravity Claude Code session but do not start any external process.

## Runtime Evidence

`prepare-runtime-launch` expects one executor packet:

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 prepare-runtime-launch -InputPath .specbridge/executor-packets/example.executor-packet.json -OutputPath .specbridge/runtime-launches/example.runtime-launch.json
```

The output must be declared under `.specbridge/runtime-launches/` and end with `.runtime-launch.json`.

`preflight-runtime-launches` expects a comma-separated list of runtime launch plans or a directory under `.specbridge/runtime-launches`:

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 preflight-runtime-launches -InputPath ".specbridge/runtime-launches/issue-097-status.runtime-launch.json,.specbridge/runtime-launches/issue-097-tests.runtime-launch.json,.specbridge/runtime-launches/issue-097-docs.runtime-launch.json" -RequiredSlice status,tests,docs -AllowedTool Read,Write,Edit -MaxBudgetUsd 2.00 -OutputPath .specbridge/preflights/issue-099-runtime-launch-preflight.runtime-preflight.json
```

When `OutputPath` is provided, it must be declared under `.specbridge/preflights/` and end with `.runtime-preflight.json`.

The command fails deterministically when required slices are missing, slice ids are duplicated, write scopes overlap, a launch budget exceeds the preflight limit, a launch uses a tool outside the configured allow-list, or any plan-only execution policy boolean is missing, non-boolean, or not `false`.

`record-runtime-result` expects one runtime launch plan and one declared executor evidence file:

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 record-runtime-result -InputPath .specbridge/runtime-launches/example.runtime-launch.json -EvidencePath .specbridge/runtime-evidence/example.md -OutputPath .specbridge/runtime-results/example.runtime-result.json -Validation "example validation: passed" -PolicyResult "Passed." -CompletionStatus complete
```

The output must be declared under `.specbridge/runtime-results/` and end with `.runtime-result.json`.

`summarize-runtime` expects one runtime launch plan and one runtime result:

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 summarize-runtime -InputPath .specbridge/runtime-launches/example.runtime-launch.json -EvidencePath .specbridge/runtime-results/example.runtime-result.json -OutputPath .specbridge/runtime-summaries/example.runtime-summary.json
```

The output must be declared under `.specbridge/runtime-summaries/` and end with `.runtime-summary.json`.

Runtime evidence commands are file-backed evidence operations. They do not launch Claude Code, launch Antigravity, run shell commands, call GitHub, install dependencies, touch secrets, or deploy anything.

## Branch Orchestration

`plan-executor-branches` expects either one executor packet file or a directory under `.specbridge/executor-packets`.

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 plan-executor-branches -TaskId issue-059-branch-per-executor-orchestration -InputPath .specbridge/executor-packets -OutputPath .specbridge/branch-plans/issue-059-branch-per-executor-orchestration.branch-plan.json
```

The output must be declared under `.specbridge/branch-plans/` and end with `.branch-plan.json`.

The command rejects duplicate branch names and records PR, CI, ChatGPT audit, merge, and rollback placeholders for every executor branch.

`record-github-evidence` expects a source branch plan and a declared GitHub evidence input file:

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 record-github-evidence -InputPath .specbridge/branch-plans/issue-059-branch-per-executor-orchestration.branch-plan.json -EvidencePath .specbridge/github-evidence/issue-060-controlled-github-evidence-run.input.json -OutputPath .specbridge/branch-plans/issue-060-controlled-github-evidence-run.branch-plan.json
```

The output must be declared under `.specbridge/branch-plans/` and end with `.branch-plan.json`.

The command requires packet ids and branch names to match the source plan, rejects `simulation://` URLs, and records PR URL, PR status, CI status, ChatGPT/Codex audit status, and integration readiness for each executor branch.

`coordinate-executors` expects a branch plan file:

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 coordinate-executors -InputPath .specbridge/branch-plans/issue-059-branch-per-executor-orchestration.branch-plan.json -OutputPath .specbridge/orchestrations/issue-059-branch-per-executor-orchestration.executor-orchestration.json -EvidenceMode simulation
```

The output must be declared under `.specbridge/orchestrations/` and end with `.executor-orchestration.json`.

Simulation mode writes explicit simulated PR, CI, and audit evidence and cannot authorize merge. GitHub evidence mode requires real GitHub PR URLs, passed CI, and approved ChatGPT audit status before integration can be marked ready.

## Test Coverage

`scripts/test-specbridge-cli.ps1` verifies:

- `status`
- `status -IncludeLatestArtifacts`
- `validate`
- `create-contract`
- `create-report`
- `audit-packet`
- `decompose-task`
- `prepare-executors`
- `prepare-runtime-launch`
- `record-runtime-result`
- `summarize-runtime`
- `plan-executor-branches`
- `record-github-evidence`
- `coordinate-executors`
- `detect-conflicts`
- `review-gate`
- deterministic failure when a required output path is missing
- deterministic failure when runtime launch and runtime result artifacts do not match

`scripts/specbridge-smoke.ps1` runs the CLI suite in CI.
