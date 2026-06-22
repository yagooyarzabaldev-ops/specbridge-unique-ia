# Current Goal

## Goal

Repository health: pay down infrastructure debt (CI duplication, branch debt, artifact growth, monolith script) before extending the multi-agent layer.

## Current Phase

Foundation complete. V5 live parallel pilot complete and merged. Full autonomous loop proven end-to-end. run_id tracing added across all artifacts. Studio dashboard operational. Post-merge closure cycle clean. Multi-agent orchestration manifest merged (issue-178). Maintenance and hardening phase.

## Completion History

| Issue | Task | PR | Status |
|-------|------|----|--------|
| 142 | Apply-mode issue_create (full 6-op loop) | 143 | Merged 2026-06-08 |
| 143 | SpecBridge intake bridge (ChatGPT entry point) | 155 | Merged 2026-06-08 |
| 149 | SpecBridge operator hardening (10 improvements) | 155 | Merged 2026-06-08 |
| 153 | Lifecycle guard for apply-mode ordering | 155 | Merged 2026-06-08 |
| 156 | Intake bridge end-to-end test (setup + fixes) | 156, 163 | Merged 2026-06-08 |
| 157 | Intake bridge end-to-end test (execution) | 158-162 | Merged 2026-06-08 |
| 159/166 | specbridge quickstart command | 167-169 | Merged 2026-06-08 |
| — | doctor --fix-plan + lifecycle debt dashboard fix | 170 | Merged 2026-06-08 |
| 172 | specbridge trace — run_id end-to-end propagation | 173 | Merged 2026-06-09 |
| 174 | SpecBridge Studio dashboard MVP | 175 | Merged 2026-06-09 |
| — | Post-merge closure: scope completed, dashboards regenerated | 176 | Merged 2026-06-09 |
| 177 | Repo memory cleanup after trace and studio | 179 | Merged 2026-06-09 |
| 178 | Multi-agent orchestration manifest (specbridge-orchestrate) | 180 | Merged 2026-06-09 |
| — | Post-merge closure issue-178 + P0 repo hygiene (ledger tracked) | 181 | Merged 2026-06-09 |
| — | Execution environment rules, docs index, merge policy clarification | 182 | Merged 2026-06-09 |
| — | specbridge.ps1 split into scripts/lib modules + explicit UTF-8 reads | 183 | Merged 2026-06-09 |
| 179/#184 | Agent handoff protocol (specbridge-handoff) + no-op validator fix | 185 | Merged 2026-06-09 |
| — | Post-merge closure issue-179: first orchestration completed 7/7 | 186 | Merged 2026-06-09 |
| — | Governed workflow-change authorization registry | 187 | Merged 2026-06-09 |
| — | Foundation Validation workflow dedup (smoke is the single gate) | 189 | Merged 2026-06-09 |
| 180/#188 | Independent review-agent report (specbridge-review-report) | 190 | Merged 2026-06-09 |
| — | Post-merge closure issue-180: second orchestration completed 7/7 | 191 | Merged 2026-06-09 |
| 181/#192 | Claude Code project config (.claude settings, sb-* commands) | 193 | Merged 2026-06-10 |
| — | Post-merge closure issue-181: third orchestration completed 7/7 | 195 | Merged 2026-06-10 |
| queue/#196 | Operator queue hygiene + next-task selector | 197 | Merged 2026-06-10 |
| 199 | V5 Serious Live Pilot - no coordinator remediation | 201 | Merged 2026-06-11 |
| 200 | Studio Operator Queue rendering fix | 200 | Merged 2026-06-15 |
| — | Post-merge closure: Studio queue memory and dashboards | 203 | Merged 2026-06-15 |
| — | Historical doctor warning reconciliation | 204 | Merged 2026-06-15 |
| 206 | MCP resource exports for operator state | 207 | Merged 2026-06-15 |
| 209 | Artifact inventory status | 210 | Merged 2026-06-15 |
| 212 | Branch inventory status | 213 | Merged 2026-06-15 |
| 215 | Governed branch cleanup policy draft | 216 | Merged 2026-06-15 |
| 218 | Governed artifact retention policy draft | 219 | Merged 2026-06-15 |
| 221 | Repository health summary evidence | 222 | Merged 2026-06-16 |
| 224 | Token and context governance standard | 225 | Merged 2026-06-16 |
| 228 | Standard readiness status | 229 | Merged 2026-06-20 |
| 231 | Claude runtime capability negotiation | 232 | Merged 2026-06-21 UTC |
| 234 | Read-only MCP runtime and backlog hygiene closure | 235 | Merged 2026-06-21 UTC |
| 237 | Governed project starter standard | 238 | Merged 2026-06-22 UTC |
| 240 | Bounded local MCP tools runtime | 241 | Merged 2026-06-22 UTC |
| 243 | specbridge.next-task bounded MCP tool | 244 | Merged 2026-06-22 UTC |

## Architecture Status

SpecBridge currently has:
- Intake bridge (specbridge-intake)
- Execution contracts, scopes, evidence
- Automatic PR creation and CI gating
- run_id end-to-end (intake → scope → contract → ledger → dashboard)
- doctor --fix-plan (offline health checks)
- Status dashboard (docs/status-dashboard.html)
- Studio dashboard with run-grouped ledger view (docs/specbridge-studio.html)
- Post-merge closure cycle (scope → completed, issue closed, current-goal reset)
- Multi-agent orchestration manifests (specbridge-orchestrate, 7 agent roles)
- Agent handoff protocol (specbridge-handoff: sequential handoffs, output artifacts, ledger entries, validator-enforced consistency)
- Modular CLI (scripts/lib/, 109-line entry point, explicit UTF-8 reads)
- Machine-validated review-agent reports (specbridge-review-report; reviewer handoff hard-gated on verdict approve with no blocker findings)
- Governed workflow-change authorization registry (.specbridge/policies/workflow-change-authorizations.json)
- Claude Code project config (.claude/settings.json bounded allowlist; /sb-intake, /sb-handoff, /sb-review, /sb-close; operating model in CLAUDE.md)
- Operator queue hygiene (operator-task-decisions registry; specbridge-next-task offline selector; open GitHub issues are storage, the registry decides eligibility)
- Artifact inventory status (specbridge-artifact-inventory: deterministic read-only evidence family counts, bytes, latest modified timestamps, preservation posture, and retention_enforcement=none)
- Branch inventory status (specbridge-branch-inventory: deterministic read-only local/origin branch ref counts, prefix counts, merged-into-main posture, preservation posture, cleanup_permission=none, and branch_mutation_policy=none)
- Branch cleanup policy draft (specbridge-branch-cleanup-policy: deterministic read-only branch cleanup candidate classification with enforcement=none, cleanup_permission=none, future activation gates, and blocked cleanup commands/actions)
- Artifact retention policy draft (specbridge-artifact-retention-policy: deterministic read-only artifact family classification with enforcement=none, cleanup_permission=none, future activation gates, and blocked cleanup commands/actions)
- Repository health summary evidence (specbridge-repository-health-summary: deterministic read-only aggregate over branch inventory, branch cleanup policy, artifact inventory, and artifact retention policy with cleanup_permission=none and enforcement_status=none)
- Token and context governance status (specbridge-token-governance-status: deterministic read-only status over Codex context governance, Claude Code runtime limits, MCP/tool context governance, multi-agent slice governance, blocked disclosures, evidence requirements, and provider-source references)
- Standard readiness status (specbridge-standard-readiness: deterministic read-only operator readiness snapshot over doctor health, next-task posture, repository health, token/context governance, MCP resource posture, and blocked execution boundaries before new governed task intake)
- Claude runtime capability negotiation (runtime-capability-status: probes installed Claude CLI help to detect --max-turns support; execute-runtime-launch applies --max-turns only when supported and records `claude_capabilities.max_turns` plus the effective `command_summary` in runtime execution evidence)
- Bounded local MCP runtime (specbridge-mcp-runtime: local MCP-style harness for `resources/list`, `resources/read`, `tools/list`, and allowlisted read-only `tools/call` over current-goal, doctor-fix-plan, and readiness summaries; network transport, hosted server deployment, secrets, GitHub/resource mutation, and cleanup enforcement remain blocked)
- Project starter standard (specbridge-project-starter: deterministic local starter artifacts for new product ideas before implementation, dependencies, secrets, billing, deployment, or external repository mutation)

## Next Recommended Task

Active governed task: issue #246 (`issue-246-agent-sdk-light-practices`) adopts low-effort Claude Agent SDK loop practices that fit the current SpecBridge runtime: read-only MCP tool annotations, compaction/summary preservation instructions, and documentation for future result/cost/session evidence. The task explicitly blocks dependency installation, SDK hosting, hooks implementation, session persistence, network MCP transport, mutation-capable MCP tools, secrets, production, billing, auth, databases, CI/CD security changes, cleanup enforcement, and deployment.

Issue #243 (`issue-243-mcp-next-task-tool`) is complete: PR #244 merged the `specbridge.next-task` bounded local MCP tool, closed issue #243, and recorded post-merge closure evidence.

Issue #240 (`issue-240-bounded-local-mcp-tools`) is complete: PR #241 merged the bounded local MCP tools surface with `tools/list` and allowlisted read-only `tools/call`, closed issue #240, and recorded post-merge closure evidence.

Issue #237 (`issue-237-project-starter-standard`) is complete. PR #238 merged the deterministic local project starter standard, closed issue #237, recorded post-merge closure evidence, and the GitHub repository visibility is private.

Queue note: issue #194 (digital twin) stays open on GitHub but is
excluded as `not_planned` by the operator decision registry;
`specbridge-next-task` will not select it.

Backlog: future mutation-capable MCP tools, network MCP transport, hosted MCP server deployment, and GitHub/resource mutation surfaces remain blocked until a dedicated contract explicitly authorizes them.

Maintenance debt:
- Branch cleanup remains policy-only. Branch debt is observable through `specbridge-branch-inventory` and classified by `specbridge-branch-cleanup-policy`; no branch deletion, pruning, renaming, movement, archival, fetch, pull, force-push, cleanup apply mode, or retention enforcement is authorized.
- Artifact retention remains policy-only. Artifact growth is observable through `specbridge-artifact-inventory` and classified by `specbridge-artifact-retention-policy`; no artifact deletion, movement, compression, pruning, archival implementation, upload, remote mutation, cleanup apply mode, or retention enforcement is authorized.
