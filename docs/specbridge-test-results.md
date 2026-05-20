# SpecBridge Test Results

## Purpose

This document records the current local test evidence for SpecBridge.

CI evidence must still be read from GitHub pull request checks after the branch is pushed.

## Test Run

- Date: 2026-05-20
- Environment: local PowerShell workspace
- Branch: `codex/chatgpt-audit-standard`
- Scope: ChatGPT audit standard validation for ChatGPT/Codex review

## Results

| Area | Result |
| --- | --- |
| Foundation validation | passed |
| Contract validation | passed |
| Contract scope validation | passed |
| Schema validation | passed |
| Final report validation | passed |
| Audit packet validation | passed |
| ChatGPT audit validation | passed |
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
- valid audit packet fixture generation passes
- audit packet generation with missing execution contract fails
- audit packet missing required field fails
- audit packet with raw diff field fails
- valid ChatGPT audit fixture passes
- ChatGPT audit missing required dimension fails
- approved ChatGPT audit with blocking finding fails
- non-approved ChatGPT audit with merge allowed fails
- incomplete final report fails
- blocked PR path fails

## Policy Result

Passed. The change adds governance schema, validation scripts, audit evidence, audit packet evidence, test fixtures, documentation, context updates, an execution contract, a scope manifest, and a final report only. It does not add runtime product code, secrets, production configuration, deployment automation, billing, hosted dashboard implementation, MCP server implementation, GitHub App implementation, branch protection weakening, or CI/CD security weakening.

## Unresolved Risks

- CI evidence is pending until the branch is pushed and GitHub runs checks.
- Auto-merge behavior should be verified on this pull request after checks pass.
