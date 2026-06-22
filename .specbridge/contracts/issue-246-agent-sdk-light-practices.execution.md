# Execution Contract: Issue 246 Agent SDK Lightweight Practices

## Contract Metadata

- contract_id: issue-246-agent-sdk-light-practices
- run_id: sb-20260622-0246a7c9
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/246
- created_by: ChatGPT/Codex
- created_at: 2026-06-22
- autonomy_profile: full_autopilot
- risk_level: low
- status: ready_for_execution

## Goal

Adopt low-effort, source-backed Claude Agent SDK loop practices that improve SpecBridge autonomy, token/context discipline, and MCP read-only metadata without introducing a hosted SDK runtime, dependency installation, secrets, deployment, network transport, or mutation-capable tools.

## Context

The user asked to avoid repeating the same roadmap and instead implement the useful best practices that can be adopted with little work. The official Claude Code Agent SDK loop documentation describes read-only MCP tool annotations, context compaction guidance through `CLAUDE.md`, result messages with cost/usage/session evidence, budget and turn limits, permission modes, and hooks. This contract authorizes only the practices that fit the current SpecBridge local runtime and governed repository stage.

## Source References

- `README.md` - current product status and runtime posture.
- `SPECBRIDGE.md` - product contract, stop conditions, and quality gates.
- `AGENTS.md` - repository operating rules.
- `.specbridge/policy.yaml` - active policy and protected boundaries.
- `.specbridge/context/CURRENT_GOAL.md` - current stage and next task posture.
- `CLAUDE.md` - Claude Code project instructions loaded into agent context.
- `docs/specbridge-mcp-bounded-tools.md` - bounded MCP tools runtime documentation.
- `docs/specbridge-token-context-governance.md` - token/context governance standard.
- `scripts/lib/mcp-tools.ps1` - bounded local MCP tool allowlist.
- `scripts/test-specbridge-cli.ps1` - CLI regression suite.
- Anthropic Claude Code Agent SDK agent loop documentation retrieved on 2026-06-22: `https://code.claude.com/docs/en/agent-sdk/agent-loop/`.

## Autonomy Profile

```text
full_autopilot
```

## Risk Level

Low. The task adds metadata, documentation, and regression coverage around existing local read-only tools and existing context governance. It does not add new execution authority, dependencies, SDK hosting, external calls, secrets, deployment, production configuration, billing configuration, authentication, authorization, databases, or CI/CD security changes.

## Allowed Scope

```text
.specbridge/contracts/issue-246-agent-sdk-light-practices.execution.md
.specbridge/scopes/issue-246-agent-sdk-light-practices.scope.json
.specbridge/reports/issue-246-agent-sdk-light-practices.final-report.json
.specbridge/audit-packets/issue-246-agent-sdk-light-practices.audit-packet.json
.specbridge/audits/issue-246-agent-sdk-light-practices.chatgpt-audit.json
.specbridge/github-evidence/issue-246-agent-sdk-light-practices.closure.json
.specbridge/ledger/operations.ndjson
.specbridge/state/current-goal.json
.specbridge/context/CURRENT_GOAL.md
.specbridge/artifact-inventory/current.inventory.json
.specbridge/mcp-resources/operator-state.catalog.json
.specbridge/standard-readiness/current.status.json
README.md
CLAUDE.md
docs/specbridge-mcp-bounded-tools.md
docs/specbridge-token-context-governance.md
docs/status-dashboard.html
docs/specbridge-studio.html
scripts/lib/mcp-tools.ps1
scripts/test-specbridge-cli.ps1
```

## Blocked Scope

```text
.github/workflows/**
.env
.env.*
secrets/**
infra/prod/**
.mcp.json
.mcp.*.json
dependency installation
package manager files
hosted Agent SDK runtime
claude_agent_sdk imports
Node or Python SDK application host
Agent SDK hooks implementation
Agent SDK session persistence implementation
network MCP transport
hosted MCP server deployment
mutation-capable MCP tools
GitHub mutation from MCP tools
external resource mutation from MCP tools
real billing configuration
provider account configuration
API key or token storage
secret access
authentication implementation
authorization implementation
database changes
CI/CD security changes
deployment automation
production deployment
branch deletion
branch pruning
branch renaming
branch movement
branch archival
artifact deletion
artifact movement
artifact compression
artifact archival
artifact upload
cleanup apply mode
retention enforcement
issue #194 lifecycle changes
digital twin implementation
unbounded Claude Code token spending
```

## Acceptance Criteria

1. The bounded local MCP tools returned by `specbridge-mcp-runtime -Method tools/list` advertise `annotations.readOnlyHint: true`.
2. CLI regression tests fail if any allowlisted bounded MCP tool is missing the read-only annotation.
3. `CLAUDE.md` includes compaction and summary preservation instructions that preserve task objective, active contract/scope, acceptance criteria, changed/read files, validation evidence, policy decisions, session/evidence pointers, risks, and rollback notes while excluding secrets, hidden prompts, irrelevant chat, and unbounded output.
4. MCP tools documentation explains that the bounded tools are read-only in effect and marked read-only through MCP annotations for safe SDK parallel execution metadata.
5. Token/context governance documentation records which Agent SDK loop practices are adopted now and which remain future blocked work requiring dedicated contracts.
6. The implementation does not install dependencies, import or host the Agent SDK, add hooks, create session persistence, add network transport, or add mutation-capable tools.
7. Required final report, audit packet, and ChatGPT/Codex audit evidence are written.
8. Required local validations and GitHub Actions pass before merge.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contract-scopes.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/test-specbridge-cli.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-audit-packets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-chatgpt-audits.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
git diff --check
```

## Stop Conditions

Stop if the task requires secrets, provider tokens, private keys, billing configuration, provider account configuration, authentication security changes, authorization security changes, database changes, dependency installation, SDK hosting, Agent SDK hooks implementation, SDK session persistence, deployment automation, production configuration, CI/CD security changes, workflow changes, network MCP transport, hosted MCP server deployment, GitHub/resource mutation through MCP tools, branch/artifact cleanup enforcement, changing issue #194 lifecycle, implementing the digital twin, or unbounded Claude Code token spending.

## Claude Code Delegation

Claude Code may inspect and implement files in allowed scope only. Claude must keep execution bounded, local, and non-interactive. Claude must not commit, push, open pull requests, call networks, install dependencies, access secrets, or touch blocked scope.

## Merge Policy

Autonomous merge is allowed only after required local validations, GitHub CI, security gate, review gate, no protected file changes, and policy checks pass.

## Deployment Policy

No deployment is allowed.

## Final Report Requirements

Write `.specbridge/reports/issue-246-agent-sdk-light-practices.final-report.json`, `.specbridge/audit-packets/issue-246-agent-sdk-light-practices.audit-packet.json`, and `.specbridge/audits/issue-246-agent-sdk-light-practices.chatgpt-audit.json`. The report must state changed files, validations, policy result, risk result, merge status, deployment status, unresolved risks, and completion status.

## Completion Rule

Task is complete when the lightweight practices are implemented, local validations pass, GitHub checks pass, PR closes issue #246, and post-merge closure evidence is recorded.
