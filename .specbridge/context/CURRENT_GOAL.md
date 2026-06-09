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

## Next Recommended Task

**Repo improvement plan (maintenance phase)**

Approved improvement plan, in order:
1. P0 hygiene: track evidence artifacts (ledger, orchestrations, issue-to-merge-runs), expand .gitignore, delete stray outputs, clean ~170 merged branches
2. P1 CI: remove duplicated validator steps from foundation-validation.yml (smoke already runs them), document pwsh vs PS5.1 divergence in AGENTS.md
3. P2 maintainability: UTF-8 read/write helpers, split scripts/specbridge.ps1 (6,978 lines) into scripts/lib/ modules
4. P3 governance debt: archive closed-issue artifacts, docs/README.md index, align policy.yaml merge flag with actual rules

After maintenance: **issue-179 agent handoff protocol** — give life to the
agent input/output artifact pointers declared in orchestration manifests
(planner, implementer, reviewer, tester, security, docs, closure).
