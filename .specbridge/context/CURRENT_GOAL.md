# Current Goal

## Goal

Complete issue 119 (apply-mode GitHub operator pilot): add real `gh issue close` execution to `issue-to-merge-github` apply mode and merge the PR.

## Current Phase

Foundation complete. Repository-first MVP complete. Full Autopilot enabled. Test suite active. Multi-agent Antigravity architecture defined. Standard Loop v1 complete. V5 pilot readiness complete. First V5 live parallel pilot complete and merged. V5 live status and runner diagnostics complete and merged. Second V5 live autonomy pilot complete and merged. V5 runner hardening complete and merged. V5 serious pilot status complete and merged through PR 88. Issue 089 post-merge memory closure complete and merged through PR 90. Issue 091 agent stage-policy alignment complete and merged through PR 92. Issue 093 one-command Standard Loop orchestration complete and merged through PR 94. Issue 095 Standard Loop contract seed complete and merged through PR 96. Issue 097 multi-slice live pilot contract preparation complete and merged through PR 98. Issue 099 runtime launch preflight complete and merged through PR 100. Issue 101 bounded live docs slice complete and merged through PR 102. Issue 103 bounded live tests slice complete and merged through PR 104. Issue 105 bounded live status slice complete and merged through PR 106. Issue 107 post-preflight live pilot closure complete and merged through PR 108. Issue 109 governed issue-to-merge operator complete and merged through PR 110. Issue 111 issue-to-merge operator safe pilot complete and merged through PR 112. Issue 113 bounded GitHub mutation operator mode complete and merged through PR 114. Issue 115 issue-to-merge GitHub evidence loop pilot complete and merged through PR 116. Issue 117 post-merge memory closure complete, PR 118 pending CI.

Current phase is issue 119 apply-mode GitHub operator pilot.

## Active Work

Active contract: `.specbridge/contracts/issue-119-apply-mode-github-operator-pilot.execution.md`.

Issue 119 adds:

- `gh issue close` execution in `issue-to-merge-github` apply mode when all evidence gates pass
- Apply-mode guards: `apply_mode_pilot_supports_issue_close_only` scope, explicit `-Force -ConfirmGithubMutation -EvidencePath` flags
- `github_calls_performed = true` and `github_mutation_result` recorded in output
- CLI tests for apply-mode blocked gates and unsupported operations
- Documentation in `docs/specbridge-issue-to-merge-operator.md`

## Required Standard

Issue 119 completion requires:

- `scripts/specbridge.ps1` `issue-to-merge-github` apply mode calls `gh issue close` when all gates pass
- Apply-mode with blocked gates returns `apply_allowed = false` without calling `gh`
- Apply-mode with unsupported operation returns `apply_mode_pilot_supports_issue_close_only` blocker
- CLI tests pass for new apply-mode scenarios
- Local standard validation, smoke validation, CLI tests, security gate, review gate, and whitespace validation pass
- GitHub CI passes before merge

## Next Recommended Task

After issue 119 merges and issue 119 is closed via apply mode:

Evaluate next expansion of the apply-mode pilot — either `pr_open` or `merge` operations, or a full end-to-end apply-mode run for a new task.

## Completion Condition

Issue 119 is locally complete when CLI changes, tests, docs, artifacts, final report, audit packet, and ChatGPT/Codex audit pass. It is repository-complete when PR 120 passes GitHub CI, merges under policy gates, and apply mode closes issue 119.
