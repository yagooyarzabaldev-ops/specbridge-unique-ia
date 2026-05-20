# SpecBridge Contract Scope Validator

## Purpose

The contract scope validator prevents unsafe parallel agent work before Claude Code execution starts.

It gives SpecBridge a deterministic way to detect whether two active contracts are trying to own the same write path, whether shared read/write relationships have explicit dependencies, and whether each contract has a unique final report target.

## Scope Manifest

Each governed contract that participates in multi-agent coordination should have a scope manifest under:

```text
.specbridge/scopes/*.scope.json
```

Required fields:

```json
{
  "contract_id": "issue-000-example",
  "status": "active",
  "exclusive_write": [
    "docs/example.md"
  ],
  "read_only": [
    "README.md"
  ],
  "coordinator_owned": [],
  "dependencies": [],
  "final_report": ".specbridge/reports/issue-000-example.final-report.json"
}
```

## Field Rules

- `contract_id` must be a non-empty string.
- `status` must be `planned`, `ready_for_execution`, `active`, `blocked`, `completed`, or `cancelled`.
- `exclusive_write` must list repository-relative paths the contract owns for writes.
- `read_only` must list repository-relative paths the contract may inspect but not change.
- `coordinator_owned` must list repository-relative shared paths controlled by the SpecBridge Coordinator.
- `dependencies` must list contract ids that must complete or be integrated before this contract can safely proceed.
- `final_report` must be a repository-relative path under `.specbridge/reports/` ending in `.final-report.json`.

## Conflict Rules

The validator checks `planned`, `ready_for_execution`, and `active` manifests for coordination conflicts.

It fails when:

- a required property is missing
- a path is empty, absolute, or traverses parent directories
- one manifest repeats a path in the same ownership list
- one contract marks the same path as both `exclusive_write` and `read_only`
- one contract marks the same path as both `exclusive_write` and `coordinator_owned`
- two active contracts declare the same `exclusive_write` path
- an active contract writes a path another active contract marks as `coordinator_owned`
- a contract reads a path another active contract writes without declaring that writer as a dependency
- two manifests declare the same `contract_id`
- two manifests declare the same `final_report`

Completed, blocked, and cancelled manifests are still checked for shape and report uniqueness, but they do not participate in active write-conflict detection.

## Validation Command

Run:

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/validate-contract-scopes.ps1
```

The script has deterministic exit codes:

- `0`: all scope manifests are valid
- `1`: one or more manifests are missing, invalid, or conflicting

## Multi-Agent Use

Before starting parallel Claude Code executors in Antigravity, the SpecBridge Coordinator should:

1. Create one execution contract per executor.
2. Create one scope manifest per execution contract.
3. Put all not-yet-started contracts in `planned`, `ready_for_execution`, or `active`.
4. Run the contract scope validator.
5. Start executors only if validation passes.

This keeps each agent inside a declared write boundary and turns overlap into a pre-execution failure instead of a late merge conflict.
