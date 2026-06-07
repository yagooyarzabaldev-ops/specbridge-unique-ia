# Current Goal

## Goal

Complete issue 123 (apply-mode pr_open expansion): expand `issue-to-merge-github` apply mode to support `gh pr create` via the `pr_open` operation and merge the PR.

## Current Phase

Foundation complete. Repository-first MVP complete. Full Autopilot enabled. Test suite active. Multi-agent Antigravity architecture defined. Standard Loop v1 complete. V5 pilot readiness complete. First V5 live parallel pilot complete and merged. V5 live status and runner diagnostics complete and merged. Second V5 live autonomy pilot complete and merged. V5 runner hardening complete and merged. V5 serious pilot status complete and merged through PR 88. Issue 089 post-merge memory closure complete and merged through PR 90. Issue 091 agent stage-policy alignment complete and merged through PR 92. Issue 093 one-command Standard Loop orchestration complete and merged through PR 94. Issue 095 Standard Loop contract seed complete and merged through PR 96. Issue 097 multi-slice live pilot contract preparation complete and merged through PR 98. Issue 099 runtime launch preflight complete and merged through PR 100. Issue 101 bounded live docs slice complete and merged through PR 102. Issue 103 bounded live tests slice complete and merged through PR 104. Issue 105 bounded live status slice complete and merged through PR 106. Issue 107 post-preflight live pilot closure complete and merged through PR 108. Issue 109 governed issue-to-merge operator complete and merged through PR 110. Issue 111 issue-to-merge operator safe pilot complete and merged through PR 112. Issue 113 bounded GitHub mutation operator mode complete and merged through PR 114. Issue 115 issue-to-merge GitHub evidence loop pilot complete and merged through PR 116. Issue 117 post-merge memory closure complete and merged through PR 118. Issue 119 apply-mode GitHub operator pilot complete and merged through PR 120. Issue 121 post-merge memory closure and ErrorActionPreference fix complete and merged through PR 122.

Current phase is issue 123 apply-mode pr_open expansion, PR 124 pending CI.

## Active Work

Active contract: `.specbridge/contracts/issue-123-apply-mode-pr-open.execution.md`.

Issue 123 adds:

- `gh pr create` execution in `issue-to-merge-github` apply mode when `pr_open` is selected and all evidence gates pass
- Pilot scope guard expanded: both `issue_close` and `pr_open` are allowed (blocker: `apply_mode_pilot_supports_issue_close_and_pr_open_only` for other ops)
- ErrorActionPreference guard applied around `gh pr create` (consistent with issue 121 fix)
- `github_mutation_result` records `pr_url`, `pr_number`, `head`, `base`, `repository`, `gh_exit_code`, `status`
- `apply-unsupported-op` test updated to use `merge` operation and check for `apply-pilot-supports-issue_close-and-pr_open` boundary string
- Documentation updated in `docs/specbridge-issue-to-merge-operator.md`

## Required Standard

Issue 123 completion requires:

- `scripts/specbridge.ps1` calls `gh pr create` for `pr_open` apply-mode when all gates pass
- Pilot scope guard allows `issue_close` and `pr_open`; unsupported op uses new blocker string
- CLI tests pass with updated boundary string check
- All local validators pass
- GitHub CI passes before merge

## Completion History

| Issue | Task | PR | Status |
|-------|------|----|--------|
| 119 | Apply-mode GitHub operator pilot (issue_close) | 120 | Merged 2026-06-06 |
| 121 | Post-merge closure + ErrorActionPreference fix | 122 | Merged 2026-06-06 |
| 123 | Apply-mode pr_open expansion | 124 | Pending CI |
| 125 | Post-merge closure + live pr_open execution | TBD | Planned |
| 127 | Apply-mode merge expansion | TBD | Planned |
| 129 | Full end-to-end apply-mode loop test | TBD | Planned |

## Next Recommended Task

After issue 123 merges: issue 125 (post-merge closure + live pr_open apply-mode execution), then issue 127 (merge operation expansion).
