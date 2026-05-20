# SpecBridge Controlled Implementation Pilot

## Purpose

This document records the first controlled implementation pilot after the local SpecBridge CLI.

The pilot proves that SpecBridge can move from repository contracts and validation artifacts into a small real implementation while preserving scope, tests, security review, audit evidence, and automatic merge gates.

## Pilot Loop

```text
ChatGPT / Codex defines the task.
SpecBridge records the execution contract and scope.
Claude Code implements a small feature inside the declared files.
SpecBridge validation runs locally and in CI.
ChatGPT / Codex audits the result against the packet and final report.
GitHub merges only after required gates pass.
```

## Implemented Feature

The local CLI `status` command now supports `-IncludeLatestArtifacts`.

When enabled, the command returns a `latest_artifacts` object containing repository-relative paths for:

- latest execution contract
- latest contract scope manifest
- latest final report
- latest audit packet
- latest ChatGPT audit

The latest selection is deterministic. Files beginning with `issue-<number>` are ordered by issue number first and then by file name.

## Acceptance Mapping

| Requirement | Evidence |
| --- | --- |
| Feature code is intentionally small. | The implementation is limited to `scripts/specbridge.ps1`. |
| Tests are included. | `scripts/test-specbridge-cli.ps1` covers `status -IncludeLatestArtifacts`. |
| Security review is included. | `scripts/validate-security-gates.ps1` and `scripts/validate-review-gate.ps1` are required validations. |
| Final report records evidence. | `.specbridge/reports/issue-053-controlled-implementation-pilot.final-report.json` records files, validations, policy, risk, and merge status. |
| ChatGPT audit checks the implementation. | `.specbridge/audits/issue-053-controlled-implementation-pilot.chatgpt-audit.json` references the audit packet, contract, and final report. |
| Automatic merge remains gated. | The execution contract allows merge only after CI, validation, policy, and review gates pass. |

## Product Result

This pilot does not introduce a hosted service, MCP server, GitHub App, database schema, dependency runtime, production deployment, billing flow, authentication implementation, or authorization implementation.

It proves the smallest useful implementation loop before the next product milestone: a multi-agent pilot with independent executor scopes.

## Next Step

Run the multi-agent pilot with separate contracts for implementation, tests, and documentation or integration. Each executor must own a non-overlapping write scope, publish evidence, and feed a coordinator integration report.
