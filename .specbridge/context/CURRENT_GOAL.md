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

## Next Recommended Task

**visual-digital-twin-rosario-mvp** (intake already triggered by the
operator; branch `codex/visual-digital-twin-rosario-mvp` exists).

This is the first product task to run on the full governance stack:
intake -> orchestrate -> handoff chain -> review report -> PR/CI ->
human-authorized merge -> closure. Note for the executor: the intake
branch was cut before PR #193 and this closure merged; rebase onto main
and resolve the `current-goal.json` conflict in favor of the new intake
(same pattern as the issue-178 rebase).

Backlog alternative: **issue-182 — MCP resources** exposing current-goal,
fix-plan and orchestration state as MCP resources for external agents.

Maintenance debt: none open.
