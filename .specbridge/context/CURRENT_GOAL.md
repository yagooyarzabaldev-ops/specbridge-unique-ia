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

## Next Recommended Task

**Operator health cleanup before the next product expansion**

Immediate order:

1. Repair PR #200 (`fix-studio-operator-queue-rendering`) so Foundation Validation passes.
2. Close remaining doctor warnings for historical completed scopes that are missing closure evidence.
3. Open a new governed operator task only after `specbridge-doctor` returns healthy or the remaining warnings are explicitly accepted.

Queue note: issue #194 (digital twin) stays open on GitHub but is
excluded as `not_planned` by the operator decision registry;
`specbridge-next-task` will not select it.

Backlog: issue-182 MCP resources (current-goal, fix-plan, orchestrations
as MCP resources for external agents).

Maintenance debt:
- PR #200 is open and failed Foundation Validation because its execution contract is missing required sections.
- `specbridge-doctor` reports missing closure evidence for `issue-172-specbridge-trace-run-id` and `issue-177-repo-memory-cleanup-after-studio`.
