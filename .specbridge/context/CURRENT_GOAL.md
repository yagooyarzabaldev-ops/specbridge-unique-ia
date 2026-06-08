# Current Goal

## Goal

Issue 153 (lifecycle guard): fix apply-mode lifecycle ordering — post_merge_memory blocked unless PR MERGED, issue_close blocked unless merge_completed, lifecycle-guard CLI command, doctor blocks on violations, dashboard Open Lifecycle Debt section.

## Current Phase

Foundation complete. Repository-first MVP complete. Full Autopilot enabled. V5 live parallel pilot complete and merged. Apply-mode pilot series complete through issue 142 (all 6 operations live). Issue 143 intake bridge complete. Issue 149 operator hardening complete (PR 150 pending merge). Current phase is issue 153 lifecycle guard.

## Completion History

| Issue | Task | PR | Status |
|-------|------|----|--------|
| 119 | Apply-mode GitHub operator pilot (issue_close) | 120 | Merged 2026-06-06 |
| 121 | Post-merge closure + ErrorActionPreference fix | 122 | Merged 2026-06-06 |
| 123 | Apply-mode pr_open expansion | 124 | Merged 2026-06-07 |
| 125 | Post-merge closure + live pr_open demo | 128 | Merged 2026-06-07 |
| 126 | Apply-mode merge expansion | 129 | Merged 2026-06-07 |
| 127 | Full end-to-end apply-mode loop test | 130 | Merged 2026-06-07 |
| 131 | Post-merge closure for 126 and 127 | 132 | Merged 2026-06-07 |
| 133 | Post-merge closure for issue 126 | 133 | Merged 2026-06-07 |
| 134 | Live combined apply-mode demonstration | 135, 137 | Merged 2026-06-07 |
| 138 | Post-merge closure for issue 134 | 139 | Merged 2026-06-07 |
| 140 | ci_wait + post_merge_memory expansion | 141 | Merged 2026-06-07 |
| 142 | Apply-mode issue_create (full 6-op loop) | 143 | Merged 2026-06-08 |
| 143 | SpecBridge intake bridge (ChatGPT entry point) | 147 | Merged 2026-06-08 |
| 149 | SpecBridge operator hardening (10 improvements) | 150 | Open, auto-merge on |
| 153 | Lifecycle guard for apply-mode ordering | TBD | In Progress |

## Next Recommended Task

After issue 153 merges: test the full system end-to-end from ChatGPT via `gh workflow run specbridge-intake.yml` with a real product feature task.
