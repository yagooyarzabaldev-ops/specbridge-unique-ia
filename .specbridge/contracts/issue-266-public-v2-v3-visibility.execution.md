# Execution Contract: Issue 266 Public Visibility and Branch Protection for v2/v3

## Contract Metadata

- contract_id: issue-266-public-v2-v3-visibility
- run_id: sb-20260628-0266public
- related_issue: https://github.com/yagooyarzabaldev-ops/specbridge/issues/266
- created_by: ChatGPT/Codex
- created_at: 2026-06-28
- autonomy_profile: full_autopilot
- risk_level: high
- status: completed

## Goal

Temporarily make `yagooyarzabaldev-ops/specbridge-v2` and
`yagooyarzabaldev-ops/specbridge-v3` public so GitHub Free branch protection can
be applied while those repositories are under active construction.

## Context

GitHub branch protection for private repositories requires GitHub Pro, Team, or
Enterprise. The operator chose the temporary public-visibility path after being
warned that public exposure can be copied by third parties and is not fully
reversible.

SpecBridge policy normally blocks public visibility changes. This contract is
the dedicated explicit authorization for this bounded visibility mutation.

## Source References

- GitHub issue #266
- User authorization in current Codex thread: "pongamoslo publico"
- README.md
- SPECBRIDGE.md
- AGENTS.md
- .specbridge/policy.yaml
- .specbridge/context/CURRENT_GOAL.md
- GitHub documentation for protected branches and plan availability

## Autonomy Profile

Full autopilot is authorized only for the bounded visibility and branch
protection work declared here.

The agent may audit tracked files, record evidence, change repository visibility
for `specbridge-v2` and `specbridge-v3`, apply branch protection to `master`,
commit evidence, push a branch, open a PR, wait for CI, merge after gates pass,
and close issue #266.

The agent must stop for any discovered secret, private key, credential,
production configuration, billing material, auth material, database credential,
dependency installation need, destructive cleanup, force push, branch deletion,
or CI/CD workflow code change.

## Risk Level

High. Repository visibility change can expose repository contents publicly and
is not fully reversible after third-party cloning. The work is allowed only
because the operator explicitly authorized public visibility for v2/v3 and the
pre-publication audit is required before mutation.

## Allowed Scope

```text
GitHub repository visibility for yagooyarzabaldev-ops/specbridge-v2
GitHub repository visibility for yagooyarzabaldev-ops/specbridge-v3
GitHub branch protection for yagooyarzabaldev-ops/specbridge-v2 master
GitHub branch protection for yagooyarzabaldev-ops/specbridge-v3 master
.specbridge/contracts/issue-266-public-v2-v3-visibility.execution.md
.specbridge/scopes/issue-266-public-v2-v3-visibility.scope.json
.specbridge/github-evidence/issue-266-public-v2-v3-visibility.issue.json
.specbridge/github-evidence/issue-266-public-v2-v3-visibility.repo-before.json
.specbridge/github-evidence/issue-266-public-v2-v3-visibility.secret-audit.json
.specbridge/github-evidence/issue-266-public-v2-v3-visibility.visibility.json
.specbridge/github-evidence/issue-266-public-v2-v3-visibility.branch-protection.json
.specbridge/github-evidence/issue-266-public-v2-v3-visibility.ci.json
.specbridge/reports/issue-266-public-v2-v3-visibility.final-report.json
.specbridge/audit-packets/issue-266-public-v2-v3-visibility.audit-packet.json
.specbridge/audits/issue-266-public-v2-v3-visibility.chatgpt-audit.json
```

## Blocked Scope

```text
secrets
.env
.env.*
private keys
production configuration
billing configuration
authentication implementation
authorization implementation
database changes
database credentials
deployment automation
dependency installation
package manager execution
CI/CD workflow code changes
any repository other than specbridge-v2 and specbridge-v3
force push
branch deletion
remote deletion
destructive cleanup
source rewrites in v2 or v3
```

## Stop Conditions

- The pre-publication audit finds tracked secret files, private keys,
  credentials, or production/billing/auth/database material.
- GitHub refuses visibility or protection changes for a reason other than a
  documented plan or permission boundary.
- Branch protection requires changing CI workflow code.
- Any required validation cannot run or fails in a way that cannot be fixed
  inside the declared evidence scope.
- Any action would touch blocked scope.

## Acceptance Criteria

1. v2 and v3 tracked-file audit evidence is recorded before public visibility.
2. No tracked protected filenames or credential-like content are found, except
   explicitly classified false positives.
3. `specbridge-v2` is public.
4. `specbridge-v3` is public.
5. `master` branch protection is applied for both repositories or exact blocker
   evidence is recorded.
6. Branch protection blocks force pushes and deletions.
7. Branch protection requires the existing CI check before updates to `master`.
8. SpecBridge evidence validators pass.
9. `./scripts/specbridge-smoke.ps1` passes.
10. Final report records rollback notes for returning v2/v3 to private later.

## Required Validations

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contracts.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-contract-scopes.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-final-reports.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-audit-packets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/validate-chatgpt-audits.ps1
git diff --check
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge-smoke.ps1
```

## Merge Policy

Branch-based work is required. Merge is allowed only after the public visibility
mutation, branch protection evidence, local validations, PR CI, review gate, and
policy evidence pass.

## Deployment Policy

No deployment is authorized. This contract changes repository visibility and
branch protection only.

## Final Report Requirements

Write `.specbridge/reports/issue-266-public-v2-v3-visibility.final-report.json`,
`.specbridge/audit-packets/issue-266-public-v2-v3-visibility.audit-packet.json`,
and `.specbridge/audits/issue-266-public-v2-v3-visibility.chatgpt-audit.json`.

## Completion Rule

This task is complete when v2/v3 public visibility and branch protection are
applied or exact blockers are recorded, all evidence is merged to SpecBridge v1
main, and issue #266 is closed as completed.
