# SpecBridge Test Results

## Purpose

This document records the current local test evidence for SpecBridge.

CI evidence must still be read from GitHub pull request checks after the branch is pushed.

## Test Run

- Date: 2026-05-20
- Environment: local PowerShell workspace
- Branch: `codex/contract-scope-validator`
- Scope: contract scope validation for multi-agent coordination

## Results

| Area | Result |
| --- | --- |
| Foundation validation | passed |
| Contract validation | passed |
| Contract scope validation | passed |
| Schema validation | passed |
| Final report validation | passed |
| PR review report validation | passed |
| Claude review workflow validation | passed |
| Autonomous execution protocol validation | passed |
| Review gate validation | passed |
| Negative validation suite | passed |
| Smoke validation | passed |
| Git diff check | passed |

## Negative Test Coverage

The negative validation suite verifies:

- missing required foundation file fails
- incomplete execution contract fails
- disjoint active contract scope manifests pass
- missing contract scope `exclusive_write` fails
- conflicting active contract write paths fail
- duplicate contract scope final report paths fail
- incomplete final report fails
- blocked PR path fails

## Policy Result

Passed. The change adds governance validation, scope manifest documentation, test fixtures, context updates, an execution contract, and a final report only. It does not add runtime product code, secrets, production configuration, deployment automation, billing, hosted dashboard implementation, MCP server implementation, GitHub App implementation, branch protection weakening, or CI/CD security weakening.

## Unresolved Risks

- CI evidence is pending until the branch is pushed and GitHub runs checks.
- Auto-merge behavior should be verified on this pull request after checks pass.
