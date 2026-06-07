# Current Goal

## Goal

Complete issue 123 (apply-mode pr_open expansion): add `gh pr create` execution to `issue-to-merge-github` apply mode.

## Current Phase

Foundation complete. Repository-first MVP complete. Full Autopilot enabled. Test suite active. Multi-agent Antigravity architecture defined. Standard Loop v1 complete. V5 pilot readiness complete. First V5 live parallel pilot complete and merged. V5 live status and runner diagnostics complete and merged. Second V5 live autonomy pilot complete and merged. V5 runner hardening complete and merged. V5 serious pilot status complete and merged through PR 88. Issue 089 post-merge memory closure complete and merged through PR 90. Issue 091 agent stage-policy alignment complete and merged through PR 92. Issue 093 one-command Standard Loop orchestration complete and merged through PR 94. Issue 095 Standard Loop contract seed complete and merged through PR 96. Issue 097 multi-slice live pilot contract preparation complete and merged through PR 98. Issue 099 runtime launch preflight complete and merged through PR 100. Issue 101 bounded live docs slice complete and merged through PR 102. Issue 103 bounded live tests slice complete and merged through PR 104. Issue 105 bounded live status slice complete and merged through PR 106. Issue 107 post-preflight live pilot closure complete and merged through PR 108. Issue 109 governed issue-to-merge operator complete and merged through PR 110. Issue 111 issue-to-merge operator safe pilot complete and merged through PR 112. Issue 113 bounded GitHub mutation operator mode complete and merged through PR 114. Issue 115 issue-to-merge GitHub evidence loop pilot complete and merged through PR 116. Issue 117 post-merge memory closure complete and merged through PR 118. Issue 119 apply-mode GitHub operator pilot complete and merged through PR 120. Issue 121 post-merge memory closure and ErrorActionPreference fix complete, PR 121 pending CI.

Current phase is issue 123 apply-mode pr_open expansion.

## Active Work

Next contract: `.specbridge/contracts/issue-123-apply-mode-pr-open.execution.md`.

Issue 123 adds:

- `gh pr create` execution in `issue-to-merge-github` apply mode when `pr_open` operation is selected
- Pilot scope guard updated: `apply_mode_pilot_supports_issue_close_pr_open`
- `github_mutation_result` records PR URL, PR number, head branch, base branch, gh exit code
- CLI tests for pr_open apply-mode (blocked gates, unsupported op updated)
- Documentation update

## Required Standard

Issue 123 completion requires:

- `scripts/specbridge.ps1` `issue-to-merge-github` apply mode calls `gh pr create` when `pr_open` is selected and all gates pass
- Apply-mode with blocked gates still returns `apply_allowed = false` without calling `gh`
- Pilot scope guard updated to allow `issue_close` and `pr_open`
- CLI tests pass for new pr_open apply-mode scenarios
- Local standard validation, smoke validation, CLI tests, security gate, review gate pass
- GitHub CI passes before merge

## Completion History

| Issue | Task | PR | Status |
|-------|------|----|--------|
| 119 | Apply-mode GitHub operator pilot | 120 | Merged 2026-06-06 |
| 121 | Post-merge closure + ErrorActionPreference fix | 121 | In progress |
| 123 | Apply-mode pr_open expansion | TBD | Planned |
| 125 | Apply-mode merge expansion | TBD | Planned |
| 127 | Full end-to-end apply-mode loop test | TBD | Planned |

## Next Recommended Task

After issue 123 merges: expand apply-mode to `merge` operation (issue 125), then full loop test (issue 127).
