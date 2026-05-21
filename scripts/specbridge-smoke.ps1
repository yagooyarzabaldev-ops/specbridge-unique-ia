$ErrorActionPreference = "Stop"

Write-Output "SpecBridge smoke validation started."

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$validationScripts = @(
  "./scripts/validate-foundation.ps1",
  "./scripts/validate-contracts.ps1",
  "./scripts/validate-contract-scopes.ps1",
  "./scripts/validate-schemas.ps1",
  "./scripts/validate-final-reports.ps1",
  "./scripts/validate-audit-packets.ps1",
  "./scripts/validate-chatgpt-audits.ps1",
  "./scripts/validate-executor-packets.ps1",
  "./scripts/validate-runtime-launches.ps1",
  "./scripts/validate-branch-orchestrations.ps1",
  "./scripts/validate-security-gates.ps1",
  "./scripts/validate-pr-review-reports.ps1",
  "./scripts/validate-claude-review-workflow.ps1",
  "./scripts/validate-autonomous-execution-protocol.ps1",
  "./scripts/test-specbridge-cli.ps1",
  "./scripts/test-specbridge-multi-agent-pilot.ps1",
  "./scripts/test-specbridge-executor-handoff.ps1",
  "./scripts/test-specbridge-branch-orchestration.ps1",
  "./scripts/test-specbridge-negative-validations.ps1"
)

foreach ($script in $validationScripts) {
  if (-not (Test-Path $script)) {
    Write-Output "FAIL missing validation script: $script"
    exit 1
  }

  Write-Output "Running $script"
  & powershell -NoProfile -ExecutionPolicy Bypass -File $script

  if ($LASTEXITCODE -ne 0) {
    Write-Output "FAIL validation script failed: $script"
    exit $LASTEXITCODE
  }
}

Write-Output "SpecBridge smoke validation passed."
exit 0
