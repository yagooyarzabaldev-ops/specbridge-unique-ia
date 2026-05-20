# SpecBridge Test Matrix

## Purpose

This matrix defines the required test coverage for SpecBridge's repository-first governance loop.

The test suite must prove both:

- valid SpecBridge artifacts pass
- invalid or unsafe SpecBridge artifacts fail deterministically

## Test Scope

In scope:

- foundation files
- execution contracts
- contract scope manifests
- audit packets
- schemas
- final reports
- PR review reports
- Claude review workflow guardrails
- autonomous execution protocol
- PR review gate
- smoke validation
- negative validation cases

Out of scope:

- production deployment
- billing
- secrets
- live Claude execution
- live MCP servers
- hosted dashboard runtime
- destructive infrastructure operations

## Positive Tests

| ID | Area | Command | Expected Result |
| --- | --- | --- | --- |
| ST-P001 | Foundation | `./scripts/validate-foundation.ps1` | Required files exist, Markdown fences are balanced, no blocked implementation paths exist. |
| ST-P002 | Contracts | `./scripts/validate-contracts.ps1` | Every execution contract has required sections, metadata, allowed autonomy profile, allowed risk level, allowed status, and GitHub issue URL. |
| ST-P003 | Contract Scopes | `./scripts/validate-contract-scopes.ps1` | Scope manifests declare required ownership fields, active write paths do not overlap, dependencies are explicit, and final report paths are unique. |
| ST-P004 | Schemas | `./scripts/validate-schemas.ps1` | Required JSON schemas exist and are readable. |
| ST-P005 | Final Reports | `./scripts/validate-final-reports.ps1` | Final reports are valid JSON and contain required fields. |
| ST-P006 | Audit Packets | `./scripts/validate-audit-packets.ps1` | Audit packets contain required evidence fields, repository-relative paths, validation summaries, CI status, policy result, and no raw/sensitive content fields. |
| ST-P007 | PR Review Reports | `./scripts/validate-pr-review-reports.ps1` | PR review report artifacts are valid. |
| ST-P008 | Claude Review Workflow | `./scripts/validate-claude-review-workflow.ps1` | Claude review workflow guardrails are present. |
| ST-P009 | Autonomous Protocol | `./scripts/validate-autonomous-execution-protocol.ps1` | Autonomous execution protocol guardrails are present. |
| ST-P010 | Review Gate | `./scripts/validate-review-gate.ps1` | Current changed files do not touch blocked paths or blocked workflow permissions. |
| ST-P011 | Smoke | `./scripts/specbridge-smoke.ps1` | The deterministic validation chain passes. |

## Negative Tests

| ID | Area | Fixture | Expected Failure |
| --- | --- | --- | --- |
| ST-N001 | Foundation | Remove `README.md` in a temporary copy. | Foundation validation fails with missing required file. |
| ST-N002 | Contracts | Add an execution contract without `## Goal` in a temporary copy. | Contract validation fails with missing required section. |
| ST-N003 | Contract Scopes | Add a scope manifest without `exclusive_write` in a temporary copy. | Contract scope validation fails with missing required property. |
| ST-N004 | Contract Scopes | Add two active scope manifests with the same `exclusive_write` path in a temporary copy. | Contract scope validation fails with conflicting contract ids and path. |
| ST-N005 | Contract Scopes | Add two scope manifests with the same final report path in a temporary copy. | Contract scope validation fails with duplicate final report path. |
| ST-N006 | Audit Packets | Generate an audit packet with a missing execution contract. | Audit packet generation fails with missing execution contract. |
| ST-N007 | Audit Packets | Add an audit packet missing required fields in a temporary copy. | Audit packet validation fails with missing required field. |
| ST-N008 | Audit Packets | Add an audit packet with a raw diff field in a temporary copy. | Audit packet validation fails with unexpected raw content field. |
| ST-N009 | Final Reports | Add a final report missing required fields in a temporary copy. | Final report validation fails with missing required property. |
| ST-N010 | Review Gate | Stage `src/blocked.txt` in a temporary Git repo. | Review gate fails with blocked path changed. |

## Positive Fixtures

| ID | Area | Fixture | Expected Result |
| --- | --- | --- | --- |
| ST-F001 | Contract Scopes | Add two disjoint active scope manifests in a temporary copy. | Contract scope validation passes. |
| ST-F002 | Audit Packets | Generate an audit packet from a fixture contract and final report, then validate it. | Audit packet validation passes. |

## Required Command

Run:

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/test-specbridge-negative-validations.ps1
```

The negative runner creates temporary repository copies, mutates only those copies, verifies expected failures, and removes the temporary files.

It also runs a positive contract-scope fixture proving that disjoint active manifests pass.

## Completion Rule

The SpecBridge test phase is complete when:

- all positive validations pass
- all positive fixtures pass
- all negative tests fail for the expected reason
- `specbridge-smoke` includes the negative test runner
- final report evidence records the validation result
