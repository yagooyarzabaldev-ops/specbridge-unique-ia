# Execution Contract: Issue 263 Story Sales Engine Module

## Contract Metadata

- contract_id: issue-263-story-sales-engine
- run_id: sb-20260628-0263feed
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/263
- created_by: ChatGPT/Codex
- created_at: 2026-06-28
- autonomy_profile: full_autopilot
- risk_level: medium
- status: completed

## Goal

Add a governed Story Sales Engine module that turns the uploaded `Vende en
Stories sin perder tiempo` operating idea into reusable documentation, prompts,
examples, and a manual n8n workflow skeleton for Infinite Process and client
projects.

## Context

The open GitHub issue requests a Story Sales Engine module for Instagram Stories
monetization. The repository is governed by SpecBridge policy, so the work must
stay branch-based, documentation/spec focused, and auditable through contract,
scope, final report, audit packet, and ChatGPT/Codex audit evidence.

This task does not authorize live provider configuration or payment automation.
WhatsApp and Mercado Pago may be described only as downstream funnel concepts.

## Source References

- GitHub issue #263: Add Story Sales Engine module for Instagram Stories monetization
- README.md
- SPECBRIDGE.md
- AGENTS.md
- .specbridge/policy.yaml
- .specbridge/context/CURRENT_GOAL.md

## Autonomy Profile

Full autopilot is authorized for ordinary repository work inside the allowed
scope, including source documentation, module examples, tests or validations,
evidence files, commit, push, PR creation, and merge-gate follow-up.

The agent must stop for policy conflicts, protected areas, provider secrets,
production configuration, billing, authentication, authorization, deployment,
dependency installation, or destructive operations.

## Risk Level

Medium. The work introduces a reusable product module and governance evidence,
but it is documentation/spec only and does not configure live providers,
production systems, or payment processing.

## Allowed Scope

```text
modules/story-sales-engine/
.specbridge/contracts/story-sales-engine-v1.md
.specbridge/scopes/story-sales-engine-v1.scope.yaml
.specbridge/reports/story-sales-engine-v1-final-report.md
.specbridge/audits/story-sales-engine-v1-codex-audit.md
.specbridge/contracts/issue-263-story-sales-engine.execution.md
.specbridge/scopes/issue-263-story-sales-engine.scope.json
.specbridge/github-evidence/issue-263-story-sales-engine.issue.json
.specbridge/reports/issue-263-story-sales-engine.final-report.json
.specbridge/audit-packets/issue-263-story-sales-engine.audit-packet.json
.specbridge/audits/issue-263-story-sales-engine.chatgpt-audit.json
```

## Blocked Scope

```text
secrets
.env
.env.*
private keys
production configuration
billing configuration
authentication implementation
authorization implementation
database changes
deployment automation
Meta provider setup
Instagram publishing
WhatsApp provider setup
Mercado Pago provider setup
payment processing
dependency installation
package manager execution
CI/CD changes
public visibility changes
force push
branch deletion
destructive cleanup
```

## Stop Conditions

- Any required validation cannot run or fails in a way that cannot be fixed
  inside the allowed scope.
- Any requested change requires secrets, provider credentials, billing,
  production configuration, auth changes, deployment automation, or dependency
  installation.
- Any change would require editing blocked files or weakening repository policy.
- Acceptance criteria become contradictory or impossible.

## Acceptance Criteria

1. The module is reusable for Infinite Process and client delivery.
2. The module defines inputs, outputs, workflow, acceptance criteria, and blocked scope.
3. The n8n JSON is importable as a starter/manual workflow skeleton.
4. WhatsApp and Mercado Pago are represented as funnel concepts only.
5. The change remains documentation/spec only and branch-based.
6. SpecBridge evidence is recorded and validators pass.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Content -Encoding UTF8 -Raw modules/story-sales-engine/workflows/n8n_story_calendar_generator.json | ConvertFrom-Json | Out-Null"
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contract-scopes.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-audit-packets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-chatgpt-audits.ps1
git diff --check
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
```

## Merge Policy

Branch-based work is required. Merge is allowed only after local validation,
policy validation, CI evidence, review/audit evidence, and repository gates pass.
No autonomous merge is allowed if any required gate is red or missing.

## Deployment Policy

No deployment is authorized. This contract produces repository documentation,
module assets, and governance evidence only.

## Final Report Requirements

Write `.specbridge/reports/issue-263-story-sales-engine.final-report.json`,
`.specbridge/audit-packets/issue-263-story-sales-engine.audit-packet.json`, and
`.specbridge/audits/issue-263-story-sales-engine.chatgpt-audit.json`.

## Completion Rule

This task is complete when all expected issue #263 module files and governance
evidence exist, validation passes, and the branch is ready for PR merge gates.
