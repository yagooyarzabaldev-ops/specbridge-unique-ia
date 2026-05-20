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
