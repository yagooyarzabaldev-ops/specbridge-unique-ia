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

## Next Recommended Task

**issue-180 — Independent review-agent report**

Now that handoffs are real, make the reviewer agent produce a structured,
machine-validated review report instead of a free-text summary:
- Define `.specbridge/review-reports/<task>.review-agent-report.json` schema
  (findings list with severity, file, rationale; verdict approve/block)
- `specbridge-handoff -Agent reviewer` requires or generates the report
- Validator: reviewer handoff without a valid report fails
- Wire the report into the Studio dashboard orchestration cards

Maintenance debt still open (human action required):
- foundation-validation.yml CI dedup is BLOCKED by
  validate-standard-ci-authority.ps1 (fails any commit touching
  .github/workflows/); needs a human-committed change.
