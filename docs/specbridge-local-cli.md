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
| `review-gate` | Runs security gate validation and PR review gate validation. | No |

## Validation Profiles

`specbridge validate` supports:

| Profile | Behavior |
| --- | --- |
| `standard` | Runs foundation, contract, scope, schema, final report, audit packet, ChatGPT audit, executor packet, security, review report, Claude workflow, autonomous protocol, and review gate validation. |
| `full` | Runs the standard profile plus negative validation fixtures. |
| `smoke` | Runs `scripts/specbridge-smoke.ps1`. |

The default profile is `standard`.

## Status Latest Artifacts

`status` accepts `-IncludeLatestArtifacts`.

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 status -IncludeLatestArtifacts
```

When enabled, the JSON output includes `latest_artifacts` with the newest known contract, scope, final report, audit packet, and ChatGPT audit paths.

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
- `detect-conflicts`
- `review-gate`
- deterministic failure when a required output path is missing

`scripts/specbridge-smoke.ps1` runs the CLI suite in CI.
