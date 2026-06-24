# SpecBridge v2 Product-Build Pilot

SpecBridge v2 is being created as a separate local repository so experimental implementation cannot damage SpecBridge v1.

SpecBridge v1 remains the control plane for this pilot:

- issue anchor: https://github.com/yagooyarzabaldev-ops/specbridge/issues/255
- starter: `.specbridge/project-starters/serious-product-build-pilot.project-starter.json`
- contract: `.specbridge/contracts/issue-255-serious-product-build-pilot.execution.md`
- scope: `.specbridge/scopes/issue-255-serious-product-build-pilot.scope.json`
- Claude Code evidence: `.specbridge/runtime-evidence/issue-255-specbridge-v2-claude-output.md`

## Local v2 Boundary

The authorized v2 workspace is:

```text
D:\Antigravity\Infinite Process\specbridge-v2
```

The pilot allows a local MVP only:

- operational README and AGENTS instructions
- local `.specbridge/context` package
- one execution contract
- one scope manifest
- a validation script
- source code
- local tests
- final report example

## Blocked Work

The pilot does not authorize:

- GitHub repository creation for v2
- external repository mutation for v2
- dependency installation
- hosted runtime
- production deployment
- billing or provider configuration
- secrets or private keys
- authentication or authorization implementation
- database changes
- CI/CD workflow changes
- Qwen-AgentWorld integration

## Execution Rule

Claude Code should be used for the first bounded implementation pass where possible. Codex may continue after Claude Code to fix validation failures, complete evidence, and report results.

Completion depends on evidence and validations, not agent self-certification.
