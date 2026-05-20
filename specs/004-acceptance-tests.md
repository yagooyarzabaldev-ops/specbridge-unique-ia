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
