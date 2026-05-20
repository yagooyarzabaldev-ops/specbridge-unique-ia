# SpecBridge Multi-Agent Pilot

## Purpose

This document records the first file-backed multi-agent pilot for SpecBridge.

The pilot proves that SpecBridge can represent several Claude Code executor lanes inside Antigravity without overlapping write ownership, while keeping contracts, scopes, validation, final reports, and coordinator evidence auditable.

## Pilot Shape

| Executor | Role | Contract | Owned Output |
| --- | --- | --- | --- |
| Agent A | Implementation slice | `.specbridge/contracts/issue-054-agent-a-implementation-slice.execution.md` | `.specbridge/pilot/multi-agent/agent-a-implementation-output.md` |
| Agent B | Test slice | `.specbridge/contracts/issue-055-agent-b-test-slice.execution.md` | `.specbridge/pilot/multi-agent/agent-b-test-output.md` |
| Agent C | Documentation slice | `.specbridge/contracts/issue-056-agent-c-documentation-slice.execution.md` | `.specbridge/pilot/multi-agent/agent-c-documentation-output.md` |
| Coordinator | Integration and gate owner | `.specbridge/contracts/issue-057-multi-agent-coordinator.execution.md` | `.specbridge/pilot/multi-agent/coordinator-integration-report.md` |

## Decomposition Evidence

The pilot input is stored at:

```text
.specbridge/decompositions/issue-054-multi-agent-pilot.input.json
```

The generated decomposition is stored at:

```text
.specbridge/decompositions/issue-054-multi-agent-pilot.decomposition.json
```

The decomposition has three slices and one unique `exclusive_write` path per executor.

## Conflict Detection

`scripts/test-specbridge-multi-agent-pilot.ps1` verifies:

- a three-agent decomposition succeeds
- generated slices keep disjoint write scopes
- a duplicate `exclusive_write` path fails before execution

This gives SpecBridge a deterministic local proof that overlapping executor ownership is rejected before Claude Code sessions begin.

## Final Reports

Each executor produces its own final report:

- `.specbridge/reports/issue-054-agent-a-implementation-slice.final-report.json`
- `.specbridge/reports/issue-055-agent-b-test-slice.final-report.json`
- `.specbridge/reports/issue-056-agent-c-documentation-slice.final-report.json`

The coordinator produces:

- `.specbridge/reports/issue-057-multi-agent-coordinator.final-report.json`
- `.specbridge/audit-packets/issue-057-multi-agent-coordinator.audit-packet.json`
- `.specbridge/audits/issue-057-multi-agent-coordinator.chatgpt-audit.json`

## Runtime Boundary

This pilot is intentionally repository-first.

It does not launch live parallel Claude Code sessions, create real executor branches per agent, add product runtime code, install dependencies, create an MCP server, create a GitHub App, add a hosted dashboard, touch production, or access secrets.

The next runtime expansion should run the same contract structure through separate Antigravity Claude Code sessions and branch-level PRs.
