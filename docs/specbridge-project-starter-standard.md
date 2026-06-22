# SpecBridge Project Starter Standard

The project starter standard is a local SpecBridge intake surface for new product ideas.

It turns an idea into a deterministic JSON artifact before any implementation, dependency installation, deployment, billing setup, secret handling, or external repository mutation is allowed.

## Command

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/specbridge.ps1 specbridge-project-starter `
  -TaskId "xygo-blockchain-starter" `
  -Title "XYGO blockchain starter" `
  -Goal "Define the first governed product package for a token project." `
  -TargetUser "founder,local tester" `
  -MvpScope "product vision,security boundaries,validation plan" `
  -NonGoal "production deployment,billing,wallet private key handling" `
  -OutputPath ".specbridge/project-starters/xygo-blockchain-starter.project-starter.json" `
  -Force
```

`TargetUser`, `MvpScope`, and `NonGoal` accept comma-separated values so the command works through Windows PowerShell 5.1 `-File` invocation.

If `-OutputPath` is omitted, the command prints JSON only and does not write an artifact.

When `-OutputPath` is present, the only valid path is:

```text
.specbridge/project-starters/<safe-task-id>.project-starter.json
```

Existing files require `-Force`.

## Artifact Contents

Each starter records:

- project identity, title, goal, target users, MVP scope, and non-goals
- blocked scope for unsafe or premature work
- required future specs and recommended repository files
- suggested agent architecture and parallelization rule
- validation plan
- security boundaries and security review prompts
- next SpecBridge steps
- standard boundaries proving the starter does not call networks, install dependencies, read secrets, deploy, mutate billing, or enable cleanup enforcement

## Safety Boundary

The project starter is a specification artifact, not an implementation launcher.

It must not:

- create or mutate external repositories
- install dependencies
- call networks
- read secrets, private keys, wallets, API tokens, or provider credentials
- configure billing or payment providers
- implement authentication or authorization
- change databases
- change CI/CD security
- deploy to staging or production
- create mutation-capable MCP tools
- enforce branch or artifact cleanup

These actions require future dedicated execution contracts and policy gates.

## Example Starter Uses

For a blockchain project, use the starter to record the token concept, network compatibility target, wallet safety boundary, audit needs, legal/compliance unknowns, and local test-only MVP.

For a WhatsApp and MercadoLibre AI project, use the starter to record target workflows, sales metrics, audit streams, privacy boundaries, integration risks, and the first non-production automation slice.

For a marketing automation project, use the starter to record content channels, campaign workflows, approval gates, analytics, asset provenance, and posting boundaries before any account connection.

## Next Step After a Starter

After the starter artifact is reviewed, create a GitHub issue and a dedicated SpecBridge execution contract. Implementation can then be delegated to Claude Code only inside that active contract, with non-overlapping scope, tests, CI, review, final report, audit packet, and ChatGPT/Codex audit evidence.
