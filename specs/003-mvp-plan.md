# 003 - MVP Plan

## MVP Goal

Prove that SpecBridge can convert structured ChatGPT/Codex context into autonomous Claude Code execution with policy boundaries and final reporting.

## MVP Scope

The MVP is repository-first.

It should not start as a SaaS product.

## MVP Deliverables

1. Base documentation:
   - README.md
   - SPECBRIDGE.md
   - AGENTS.md
   - CLAUDE.md

2. Policy files:
   - .specbridge/policy.yaml
   - .specbridge/autonomy.yaml
   - .specbridge/risk-rules.yaml
   - .specbridge/report-template.md

3. Specs:
   - specs/000-project-context.md
   - specs/001-product-requirements.md
   - specs/002-architecture.md
   - specs/003-mvp-plan.md
   - specs/004-acceptance-tests.md

4. Context package format:
   - .specbridge/context/CODEX_CONTEXT.md
   - .specbridge/context/CURRENT_GOAL.md
   - .specbridge/context/ACCEPTANCE_CRITERIA.md
   - .specbridge/context/DO_NOT_TOUCH.md
   - .specbridge/context/STYLE_GUIDE.md

5. Later workflow layer:
   - GitHub issue template
   - Claude Code execution workflow
   - Codex review workflow
   - basic validation workflow

## Out of Scope for MVP

- SaaS dashboard
- billing
- organization management
- production deployment automation
- unrestricted terminal execution
- multi-provider marketplace

## MVP Success Criteria

The MVP succeeds when a task can be defined as structured context, executed by Claude Code without step-by-step permission requests, validated, reviewed, and reported with evidence.

## Current Completion Status

The repository-first MVP is complete as a controlled governance loop.

Completed evidence includes:

- context package files under `.specbridge/context/`
- execution contract templates and examples under `.specbridge/contracts/`
- final report schema and examples under `.specbridge/reports/`
- PR review report schema and example under `.specbridge/review-reports/`
- deterministic validation scripts under `scripts/`
- GitHub workflow definitions under `.github/workflows/`
- Claude Code commands and rules under `.claude/`
- controlled E2E pilot documentation
- local autonomous execution protocol documentation

The MVP does not activate hosted runtime code, real MCP servers, production deployment, secret handling, or billing.

Autonomous merge is allowed only through the active policy and only after required gates pass.
