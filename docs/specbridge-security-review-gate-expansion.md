# SpecBridge Security Review Gate Expansion

## Purpose

The security review gate is a deterministic local validator for repository changes before SpecBridge expands runtime autonomy.

It is designed to fail closed when a changed file crosses a protected security category. The failure output names the category so ChatGPT/Codex, Claude Code, CI, and final reports can cite evidence instead of confidence.

## Validator

Run:

```powershell
powershell -ExecutionPolicy Bypass -File ./scripts/validate-security-gates.ps1
```

The validator inspects changed files from the pull request base when available, unstaged changes, staged changes, and the latest local commit.

## Security Categories

The gate reports failures in this format:

```text
FAIL security category=<category> path=<path> detail=<detail>
```

Supported categories:

| Category | Meaning |
| --- | --- |
| `secret_like_content` | A changed text file contains a high-confidence key, token, private key, or credential assignment shape. |
| `auth_sensitive_file` | A changed path appears to affect authentication, login, sessions, OAuth, JWT, or auth-owned files. |
| `authorization_sensitive_file` | A changed path appears to affect authorization, RBAC, access control, permissions, or policy engine files. |
| `ci_cd_permission_escalation` | A changed workflow requests global write permission or write permission for sensitive GitHub token scopes. |
| `dependency_addition` | A changed dependency manifest or lockfile would alter the dependency surface. |
| `unsafe_shell_command` | A changed text file contains a high-risk shell command pattern blocked by repository policy. |
| `protected_path_change` | A changed path is protected by policy, such as environment files, secret files, private keys, or production infrastructure paths. |
| `production_configuration` | A changed path appears to affect production configuration. |

## Acceptance Evidence

The negative validation suite covers:

- safe fixture passes
- secret-like content fails as `secret_like_content`
- auth-sensitive path fails as `auth_sensitive_file`
- authorization-sensitive path fails as `authorization_sensitive_file`
- workflow permission escalation fails as `ci_cd_permission_escalation`
- dependency manifest addition fails as `dependency_addition`
- unsafe command content fails as `unsafe_shell_command`
- protected path fails as `protected_path_change`
- production configuration path fails as `production_configuration`

## Boundary

This gate does not authorize protected changes.

When a category fails, the autonomous task must stop unless a future execution contract and policy profile explicitly authorize that class of work. Production deployment, billing, secrets, critical authentication, critical authorization, and CI/CD security weakening remain outside normal Full Autopilot execution.
