# SpecBridge CLI library: token governance
# Dot-sourced by scripts/specbridge.ps1. Do not run directly.

function Get-TokenGovernancePolicy {
  $policyPath = ".specbridge/policies/token-context-governance.json"

  if (-not (Test-Path -LiteralPath $policyPath -PathType Leaf)) {
    Fail "Token/context governance policy is missing: $policyPath"
  }

  return Get-JsonObjectFromFile -Path $policyPath -Description "token/context governance policy"
}

function New-TokenGovernanceStatus {
  param(
    [object] $Policy,
    [bool] $WritesOutputArtifact
  )

  return [ordered]@{
    command = "specbridge-token-governance-status"
    ok = $true
    schema_version = $Policy.schema_version
    governance_id = $Policy.governance_id
    status = $Policy.status
    retrieved_at = $Policy.retrieved_at
    policy_path = ".specbridge/policies/token-context-governance.json"
    provider_sources = @($Policy.provider_sources)
    codex_context_governance = $Policy.codex_context_governance
    claude_code_runtime_governance = $Policy.claude_code_runtime_governance
    mcp_tool_context_governance = $Policy.mcp_tool_context_governance
    multi_agent_slice_governance = $Policy.multi_agent_slice_governance
    blocked_disclosures = @($Policy.blocked_disclosures)
    evidence_requirements = @($Policy.evidence_requirements)
    policy_boundary = $Policy.policy_boundary
    execution_policy = [ordered]@{
      launches_claude = $false
      launches_codex = $false
      calls_network = $false
      mutates_github = $false
      reads_secrets = $false
      changes_billing = $false
      changes_ci_cd_security = $false
      deploys = $false
      writes_output_artifact = $WritesOutputArtifact
    }
    evidence_sources = @(
      ".specbridge/policies/token-context-governance.json",
      ".specbridge/contracts/issue-224-token-context-governance.execution.md",
      ".specbridge/scopes/issue-224-token-context-governance.scope.json",
      "docs/specbridge-token-context-governance.md",
      "scripts/lib/runtime.ps1",
      ".claude/settings.json"
    )
    notes = @(
      "This command is deterministic and reads local repository policy only.",
      "It does not launch Claude Code or Codex.",
      "It does not inspect, reveal, persist, or request provider tokens.",
      "It does not change real billing, provider account settings, CI/CD security, cleanup enforcement, or deployment."
    )
  }
}

function Invoke-TokenGovernanceStatusCommand {
  $output = $null
  $writesOutputArtifact = $false

  if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $output = Assert-OutputPath `
      -Path $OutputPath `
      -Pattern "^\.specbridge/token-governance/.+\.status\.json$" `
      -Description "a .specbridge/token-governance/*.status.json token governance artifact"
    $writesOutputArtifact = $true
  }

  $policy = Get-TokenGovernancePolicy
  $status = New-TokenGovernanceStatus -Policy $policy -WritesOutputArtifact $writesOutputArtifact

  if ($writesOutputArtifact) {
    Write-Utf8JsonFile -Path $output -Value $status -Depth 14
  }

  Write-CliJson $status -Depth 14
  exit 0
}
