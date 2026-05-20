# 004 - Acceptance Tests

## Foundation Acceptance Tests

### AT-001 - Required foundation files exist

Required files:

- README.md
- SPECBRIDGE.md
- AGENTS.md
- CLAUDE.md
- .gitattributes
- .specbridge/policy.yaml
- .specbridge/autonomy.yaml
- .specbridge/risk-rules.yaml
- .specbridge/report-template.md
- specs/000-project-context.md
- specs/001-product-requirements.md
- specs/002-architecture.md
- specs/003-mvp-plan.md
- specs/004-acceptance-tests.md

Pass condition:

All required files exist and are non-empty.

### AT-002 - Markdown fences are balanced

Pass condition:

All Markdown files have an even number of triple-backtick code fences.

### AT-003 - Policy files are present

Pass condition:

All YAML policy files exist and are non-empty.

### AT-004 - No implementation code during foundation phase

Pass condition:

The repository contains only documentation, specs, policy, and configuration files during foundation phase.

### AT-005 - Vibe Autopilot is defined

Pass condition:

README.md, SPECBRIDGE.md, AGENTS.md, CLAUDE.md, and .specbridge/autonomy.yaml all reference or define Vibe Autopilot behavior.

### AT-006 - Stop conditions are defined

Pass condition:

SPECBRIDGE.md, AGENTS.md, CLAUDE.md, and .specbridge/policy.yaml define stop conditions or escalation boundaries.

### AT-007 - Final report template exists

Pass condition:

.specbridge/report-template.md exists and includes sections for summary, changed files, validations, policy result, risk result, merge status, deployment status, and rollback notes.

### AT-008 - MVP operating runbook exists

Pass condition:

docs/specbridge-mvp-operating-runbook.md exists and defines required inputs, operating loop, local validations, CI gates, completion standard, failure handling, and MVP boundary.

### AT-009 - Phase completion artifact exists

Pass condition:

docs/specbridge-phase-completion.md exists and records Phase 1, Phase 2, and Phase 3 status with explicit non-activation boundaries.

### AT-010 - V3 essential scope exists

Pass condition:

docs/specbridge-v3-essential-product-scope.md exists and defines essential product capabilities, runtime boundary, non-essential scope, version 4 candidates, and the gate required before runtime work starts.

### AT-011 - V4 product contract exists

Pass condition:

docs/specbridge-v4-product-contract.md exists and defines product goal, required product surfaces, local CLI scope, MCP scope, GitHub integration scope, hosted dashboard scope, data model boundary, runtime implementation gates, V4 completion criteria, and Version 5 candidates.

### AT-012 - Automatic merge policy is explicit

Pass condition:

.specbridge/policy.yaml enables autonomous merge, .specbridge/autonomy.yaml selects `full_autopilot` as the default profile, and documentation states that automatic merge requires all configured gates to pass.

### AT-013 - Negative validation suite exists

Pass condition:

scripts/test-specbridge-negative-validations.ps1 exists and verifies that foundation validation, contract validation, final report validation, and PR review gate validation fail for expected invalid fixtures.

### AT-014 - Smoke validation includes negative tests

Pass condition:

scripts/specbridge-smoke.ps1 runs scripts/test-specbridge-negative-validations.ps1 as part of the deterministic smoke chain.

### AT-015 - Test evidence is documented

Pass condition:

docs/specbridge-test-matrix.md defines positive and negative test coverage, and docs/specbridge-test-results.md records current validation evidence.

### AT-016 - Multi-agent Antigravity architecture exists

Pass condition:

docs/specbridge-multi-agent-antigravity-architecture.md exists and defines Governor, Coordinator, Executor, Reviewer, parallel execution rules, scope ownership, branching, evidence, merge model, and product requirements for multiple Claude Code executors working inside Antigravity.

### AT-017 - Contract scope validation exists

Pass condition:

scripts/validate-contract-scopes.ps1 exists, validates `.specbridge/scopes/*.scope.json`, rejects overlapping active `exclusive_write` paths, rejects duplicate final report paths, requires explicit dependencies for active read/write relationships, and is included in scripts/specbridge-smoke.ps1.

### AT-018 - Audit packet generation exists

Pass condition:

scripts/generate-audit-packet.ps1 creates deterministic `.specbridge/audit-packets/*.audit-packet.json` files, scripts/validate-audit-packets.ps1 validates the required packet fields, packets reference files by path without embedding raw diffs or file contents, and scripts/specbridge-smoke.ps1 includes audit packet validation.

### AT-019 - ChatGPT audit validation exists

Pass condition:

.specbridge/schemas/chatgpt-audit.schema.json exists, scripts/validate-chatgpt-audits.ps1 validates `.specbridge/audits/*.chatgpt-audit.json`, allowed outcomes are limited to `approved`, `changes_requested`, `blocked`, and `needs_human_decision`, every audit checks the required dimensions, blocking findings prevent merge, and scripts/specbridge-smoke.ps1 includes ChatGPT audit validation.

### AT-020 - Security review gate expansion exists

Pass condition:

scripts/validate-security-gates.ps1 exists, scripts/specbridge-smoke.ps1 includes security gate validation, the gate checks changed files for secret-like content, auth-sensitive paths, authorization-sensitive paths, CI/CD permission escalation, dependency manifest or lockfile changes, unsafe shell commands, protected path changes, and production configuration paths, and the negative validation suite proves safe and unsafe fixtures with expected security categories.

### AT-021 - Local SpecBridge CLI exists

Pass condition:

scripts/specbridge.ps1 exists and supports `status`, `validate`, `create-contract`, `create-report`, `audit-packet`, `detect-conflicts`, `decompose-task`, and `review-gate`; commands have deterministic exit codes; artifact commands use declared repository-relative output paths; commands do not require secrets; scripts/test-specbridge-cli.ps1 covers every command; and scripts/specbridge-smoke.ps1 runs the CLI validation suite.

### AT-022 - Controlled implementation pilot exists

Pass condition:

docs/specbridge-controlled-implementation-pilot.md exists; scripts/specbridge.ps1 `status` supports `-IncludeLatestArtifacts`; the output includes deterministic latest contract, scope, final report, audit packet, and ChatGPT audit paths; scripts/test-specbridge-cli.ps1 covers the feature; and issue 053 contract, scope, final report, audit packet, and ChatGPT audit artifacts validate.
