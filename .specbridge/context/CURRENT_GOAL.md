# Current Goal

## Goal

Complete issue 109 by adding the governed issue-to-merge operator standard after the issue 107 pilot closure.

The task must move repository memory past the completed issue 107 closure, add a deterministic plan-only CLI operator command, write a file-backed issue-to-merge run artifact, update tests and documentation, and preserve the no-GitHub-mutation-from-operator, no-live-launch, no-secrets, no-production, no-deployment policy boundary.

## Current Phase

Foundation complete. Repository-first MVP complete. Full Autopilot enabled. Test suite active. Multi-agent Antigravity architecture defined. Standard Loop v1 complete. V5 pilot readiness complete. First V5 live parallel pilot complete and merged. V5 live status and runner diagnostics complete and merged. Second V5 live autonomy pilot complete and merged. V5 runner hardening complete and merged. V5 serious pilot status complete and merged through PR 88. Issue 089 post-merge memory closure complete and merged through PR 90. Issue 091 agent stage-policy alignment complete and merged through PR 92. Issue 093 one-command Standard Loop orchestration complete and merged through PR 94. Issue 095 Standard Loop contract seed complete and merged through PR 96. Issue 097 multi-slice live pilot contract preparation complete and merged through PR 98. Issue 099 runtime launch preflight complete and merged through PR 100. Issue 101 bounded live docs slice complete and merged through PR 102. Issue 103 bounded live tests slice complete and merged through PR 104. Issue 105 bounded live status slice complete and merged through PR 106. Issue 107 post-preflight live pilot closure complete and merged through PR 108.

Current phase is issue 109 governed issue-to-merge operator.

## Active Work

Active contract: `.specbridge/contracts/issue-109-governed-issue-to-merge-operator.execution.md`.

Issue 109 adds:

- one deterministic plan-only `issue-to-merge-plan` CLI operator command
- one issue-to-merge run artifact under `.specbridge/issue-to-merge-runs/`
- focused CLI coverage for success, output artifact, and missing `TaskId` failure paths
- operator documentation and local CLI documentation
- one repository memory update
- one final report
- one audit packet
- one ChatGPT/Codex audit

## Required Standard

Issue 109 completion requires:

- No GitHub mutation from the new operator command, live Claude Code, Antigravity, runtime launch, dependency installation, CI/CD security change, deployment, secrets, production, billing, auth, authorization, or database expansion occurs.
- The operator output records task id, issue reference, branch, contract path, scope path, final report path, audit packet path, ChatGPT/Codex audit path, phases, local gates, GitHub gates, merge conditions, post-merge memory closure requirements, policy boundaries, and command boundary.
- The command can write `.specbridge/issue-to-merge-runs/issue-109-governed-issue-to-merge-operator.issue-to-merge-run.json`.
- The command fails deterministically when `TaskId` is omitted.
- README and docs record the governed issue-to-merge operator standard.
- The final report, audit packet, and ChatGPT/Codex audit validate.
- Local standard validation, CLI tests, smoke validation, security gate, review gate, and whitespace validation pass.
- GitHub CI passes before merge.

## Next Recommended Task

After issue 109 merges, pilot the new issue-to-merge operator with a small safe dry-run or documentation-only task before authorizing any GitHub-mutating operator mode.

## Completion Condition

Issue 109 is locally complete when the operator command, issue-to-merge run artifact, docs, memory, final report, audit packet, ChatGPT/Codex audit, and local validations pass. It is repository-complete when its PR passes GitHub CI and merges under policy gates.
