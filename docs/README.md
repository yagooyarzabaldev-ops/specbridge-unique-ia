# SpecBridge Documentation Index

This directory accumulated documents across every project phase. This index separates what governs the repository today from historical records kept for auditability.

## Current operating documents

| Document | Purpose |
|----------|---------|
| [specbridge-standard-loop-v1.md](specbridge-standard-loop-v1.md) | The governing execution standard: 9 phases, gates, evidence |
| [specbridge-ci-authority-standard.md](specbridge-ci-authority-standard.md) | GitHub CI as merge authority; required workflows and gates |
| [specbridge-mvp-operating-runbook.md](specbridge-mvp-operating-runbook.md) | Day-to-day operator runbook |
| [specbridge-issue-to-merge-operator.md](specbridge-issue-to-merge-operator.md) | Governed issue-to-merge operator (plan + apply modes) |
| [specbridge-required-pr-gates.md](specbridge-required-pr-gates.md) | Required PR gates |
| [specbridge-review-gate.md](specbridge-review-gate.md) | Review gate contract |
| [specbridge-security-review-gate-expansion.md](specbridge-security-review-gate-expansion.md) | Security gate rules |
| [specbridge-pr-review-report-standard.md](specbridge-pr-review-report-standard.md) | PR review report format |
| [specbridge-final-report-standard.md](specbridge-final-report-standard.md) | Final report format |
| [specbridge-chatgpt-audit-standard.md](specbridge-chatgpt-audit-standard.md) | ChatGPT/Codex audit format |
| [specbridge-test-matrix.md](specbridge-test-matrix.md) / [specbridge-test-protocol.md](specbridge-test-protocol.md) | Test coverage and protocol |
| [status-dashboard.html](status-dashboard.html) | Generated status dashboard (`generate-dashboard`) |
| [specbridge-studio.html](specbridge-studio.html) | Generated Studio dashboard (`generate-studio-dashboard`) |

## Architecture references (still accurate)

- [specbridge-multi-agent-antigravity-architecture.md](specbridge-multi-agent-antigravity-architecture.md)
- [specbridge-standard-loop-orchestrator.md](specbridge-standard-loop-orchestrator.md)
- [specbridge-branch-per-executor-orchestration.md](specbridge-branch-per-executor-orchestration.md)
- [specbridge-local-cli.md](specbridge-local-cli.md)
- [context-management.md](context-management.md)
- [mcp-integration-contract.md](mcp-integration-contract.md) / [mcp-server-implementation-plan.md](mcp-server-implementation-plan.md)
- [claude-code-configuration.md](claude-code-configuration.md), [claude-code-execution-workflow.md](claude-code-execution-workflow.md), [claude-code-pr-review.md](claude-code-pr-review.md), [claude-code-ci-workflow.md](claude-code-ci-workflow.md)
- [codex-independent-review.md](codex-independent-review.md)
- [branch-protection.md](branch-protection.md)

## Historical phase records (kept for audit, no longer governing)

Roadmaps and product contracts of completed phases:
`specbridge-v2-roadmap.md`, `specbridge-v3-essential-product-scope.md`, `specbridge-v4-product-contract.md`, `specbridge-v5-*.md`, `specbridge-phase-completion.md`, `specbridge-operational-autonomy-policy-closure.md`, `specbridge-autonomy-backlog.md`.

Pilot and runtime expansion records (all pilots completed and merged):
`e2e-pilot-plan.md`, `specbridge-controlled-*.md`, `specbridge-multi-agent-pilot.md`, `specbridge-multi-slice-live-pilot-contract.md`, `specbridge-live-antigravity-executor-handoff.md`, `specbridge-fresh-executor-source-run.md`, `specbridge-serious-autonomous-test-loop.md`, `specbridge-standard-loop-feature-pilot.md`, `specbridge-runtime-*.md`, `specbridge-test-results.md`, `specbridge-chatgpt-governed-execution.md`, `specbridge-local-claude-autonomous-execution.md`, `specbridge-non-blocking-claude-review.md`, `specbridge-pr-review-comment-publishing.md`, `specbridge-pr-review-report-generator.md`, `specbridge-audit-packet-generator.md`, `specbridge-contract-scope-validator.md`, `specbridge-autonomy-metrics.md`, `specbridge-standard-templates.md`.

New documents should state at the top whether they are a governing standard or a phase record.
