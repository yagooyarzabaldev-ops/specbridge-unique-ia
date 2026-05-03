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
