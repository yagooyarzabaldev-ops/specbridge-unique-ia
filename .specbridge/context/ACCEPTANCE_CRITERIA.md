# Acceptance Criteria

## Context Package Acceptance Criteria

### AC-001

.specbridge/context/CODEX_CONTEXT.md exists and defines the structured context purpose.

### AC-002

.specbridge/context/CURRENT_GOAL.md exists and defines the current project goal.

### AC-003

.specbridge/context/ACCEPTANCE_CRITERIA.md exists and defines measurable completion criteria.

### AC-004

.specbridge/context/DO_NOT_TOUCH.md exists and defines protected areas.

### AC-005

.specbridge/context/STYLE_GUIDE.md exists and defines style rules.

### AC-006

No raw ChatGPT conversation dump is stored in the context package.

### AC-007

All context files are Markdown files and have balanced code fences.

## Phase Completion Acceptance Criteria

### AC-008

docs/specbridge-phase-completion.md exists and records foundation completion, repository-first MVP completion, and essential V3 scope status.

### AC-009

docs/specbridge-mvp-operating-runbook.md exists and defines the repository-first MVP operating loop.

### AC-010

docs/specbridge-v3-essential-product-scope.md exists and defines essential product scope, runtime boundaries, non-essential scope, and version 4 candidates.

### AC-011

.specbridge/contracts/issue-042-finish-phases-1-3.execution.md exists and defines allowed scope, blocked scope, acceptance criteria, validations, stop conditions, merge policy, deployment policy, and final report requirements.

### AC-012

.specbridge/reports/issue-042-finish-phases-1-3.final-report.json exists and validates against the final report validator.

### AC-013

No secrets, production configuration, deployment automation, runtime product code, MCP server implementation, autonomous merge, or autonomous push to main are added by the phase completion task.

## Version 4 Acceptance Criteria

### AC-014

docs/specbridge-v4-product-contract.md exists and defines V4 product goal, required surfaces, local CLI scope, MCP scope, GitHub integration scope, hosted dashboard boundary, data model boundary, runtime gates, completion criteria, and Version 5 candidates.

### AC-015

.specbridge/contracts/issue-043-finish-version-4.execution.md exists and defines allowed scope, blocked scope, acceptance criteria, validations, stop conditions, merge policy, deployment policy, and final report requirements.

### AC-016

.specbridge/reports/issue-043-finish-version-4.final-report.json exists and validates against the final report validator.

### AC-017

Version 4 completion does not add runtime product code, secrets, production configuration, hosted dashboard implementation, database schema implementation, MCP server implementation, GitHub App implementation, autonomous merge, or autonomous push to main.

## Automatic Merge Acceptance Criteria

### AC-018

.specbridge/policy.yaml sets `project.default_mode` to `full_autopilot` and `merge.autonomous_merge_enabled` to `true`.

### AC-019

.specbridge/autonomy.yaml sets `default_profile` to `full_autopilot`.

### AC-020

Documentation states that automatic merge is allowed only after required validation, policy, review, and CI gates pass.

### AC-021

Production deployment remains disabled.

## Test Suite Acceptance Criteria

### AC-022

scripts/test-specbridge-negative-validations.ps1 exists and verifies expected failure behavior for missing foundation files, incomplete execution contracts, incomplete final reports, and blocked PR paths.

### AC-023

scripts/specbridge-smoke.ps1 runs the negative validation suite.

### AC-024

docs/specbridge-test-matrix.md exists and defines positive and negative SpecBridge test coverage.

### AC-025

docs/specbridge-test-results.md exists and records the local validation evidence for the current test phase.

## Multi-Agent Architecture Acceptance Criteria

### AC-026

docs/specbridge-multi-agent-antigravity-architecture.md exists and defines multi-agent execution as a first-class product capability.

### AC-027

The architecture defines Governor, Coordinator, Executor, Reviewer, parallel execution rules, scope ownership, branch strategy, evidence aggregation, and merge behavior.

### AC-028

Product requirements and architecture specs mention multiple Claude Code executors working in parallel inside Antigravity.

## Autonomy Backlog Memory Acceptance Criteria

### AC-029

docs/specbridge-autonomy-backlog.md exists and records the remaining work for local CLI, contract scope validation, audit packet generation, ChatGPT audit standard, controlled implementation pilot, multi-agent pilot, and security gate expansion.

### AC-030

.specbridge/context/CURRENT_GOAL.md identifies the autonomy runtime preparation phase and names the contract scope validator as the recommended next task.

### AC-031

Future agents can determine the next execution order from repository files without relying on chat history.

## Contract Scope Validator Acceptance Criteria

### AC-032

scripts/validate-contract-scopes.ps1 exists and validates `.specbridge/scopes/*.scope.json` manifests.

### AC-033

Each scope manifest declares `exclusive_write`, `read_only`, `coordinator_owned`, `dependencies`, and `final_report`.

### AC-034

Active conflicting write scopes fail validation with contract ids and paths in the failure output.

### AC-035

Disjoint active scope manifests pass validation.

### AC-036

Duplicate final report paths fail validation.

### AC-037

Read/write relationships between active contracts require explicit dependencies.

### AC-038

scripts/specbridge-smoke.ps1 runs the contract scope validator.

## Audit Packet Generator Acceptance Criteria

### AC-039

scripts/generate-audit-packet.ps1 exists and creates deterministic `.specbridge/audit-packets/*.audit-packet.json` files.

### AC-040

scripts/validate-audit-packets.ps1 exists and validates required audit packet fields.

### AC-041

Audit packets include task id, execution contract path, changed files, diff summary, validation commands, validation results, final report path, CI status, PR review report path, policy result, unresolved risks, completion status, and source file references.

### AC-042

Audit packets reference source files by repository-relative path and do not embed raw diffs, file contents, secrets, tokens, private keys, or credential values.

### AC-043

Positive fixture generation passes and invalid audit packets fail for expected reasons.

### AC-044

scripts/specbridge-smoke.ps1 runs audit packet validation.

## ChatGPT Audit Standard Acceptance Criteria

### AC-045

.specbridge/schemas/chatgpt-audit.schema.json exists and defines the machine-readable ChatGPT audit output.

### AC-046

scripts/validate-chatgpt-audits.ps1 exists and validates `.specbridge/audits/*.chatgpt-audit.json`.

### AC-047

ChatGPT audit outcomes are limited to `approved`, `changes_requested`, `blocked`, and `needs_human_decision`.

### AC-048

Each audit checks spec compliance, acceptance criteria, policy boundaries, security rules, changed file scope, test evidence, CI evidence, and final report honesty.

### AC-049

Audit findings include severity, category, file, line, evidence, recommendation, and blocking status.

### AC-050

Blocking findings or dimensions prevent merge.

### AC-051

Positive audit fixtures pass and invalid audit fixtures fail for expected reasons.

### AC-052

scripts/specbridge-smoke.ps1 runs ChatGPT audit validation.

## Security Review Gate Expansion Acceptance Criteria

### AC-053

scripts/validate-security-gates.ps1 exists and validates changed files for deterministic security categories.

### AC-054

scripts/specbridge-smoke.ps1 runs security gate validation.

### AC-055

The security gate detects secret-like content, auth-sensitive paths, authorization-sensitive paths, CI/CD permission escalation, dependency manifest or lockfile changes, unsafe shell commands, protected path changes, and production configuration paths.

### AC-056

The negative validation suite includes a safe fixture that passes security gate validation.

### AC-057

The negative validation suite includes unsafe fixtures that fail for the expected security categories.

### AC-058

Security gate failures name the category in machine-readable output.

## Local SpecBridge CLI Acceptance Criteria

### AC-059

scripts/specbridge.ps1 exists and exposes the local file-backed CLI.

### AC-060

The CLI supports `status`, `validate`, `create-contract`, `create-report`, `audit-packet`, `detect-conflicts`, `decompose-task`, and `review-gate`.

### AC-061

CLI commands have deterministic exit codes and fail when required declared inputs or output paths are missing.

### AC-062

CLI artifact commands write only declared repository-relative output paths.

### AC-063

CLI commands do not require secrets and avoid network calls by default.

### AC-064

scripts/test-specbridge-cli.ps1 covers every CLI command.

### AC-065

scripts/specbridge-smoke.ps1 runs the CLI validation suite.

## Controlled Implementation Pilot Acceptance Criteria

### AC-066

docs/specbridge-controlled-implementation-pilot.md exists and records the first small implementation pilot after the local CLI.

### AC-067

scripts/specbridge.ps1 `status` supports `-IncludeLatestArtifacts`.

### AC-068

`status -IncludeLatestArtifacts` returns a `latest_artifacts` JSON object containing contract, scope, final report, audit packet, and ChatGPT audit paths.

### AC-069

Latest artifact selection is deterministic and orders `issue-<number>` artifact names by issue number before file name.

### AC-070

scripts/test-specbridge-cli.ps1 covers `status -IncludeLatestArtifacts`.

### AC-071

.specbridge/contracts/issue-053-controlled-implementation-pilot.execution.md exists and defines the pilot goal, scope, validations, stop conditions, merge policy, deployment policy, and final report requirements.

### AC-072

.specbridge/reports/issue-053-controlled-implementation-pilot.final-report.json exists and validates against the final report validator.

### AC-073

.specbridge/audit-packets/issue-053-controlled-implementation-pilot.audit-packet.json exists and validates against the audit packet validator.

### AC-074

.specbridge/audits/issue-053-controlled-implementation-pilot.chatgpt-audit.json exists and validates against the ChatGPT audit validator.

### AC-075

The controlled implementation pilot does not add secrets, production configuration, deployment automation, billing, hosted dashboard implementation, MCP server implementation, GitHub App implementation, database schema implementation, authentication implementation, authorization implementation, dependency installation, CI/CD permission escalation, or CI/CD security weakening.
