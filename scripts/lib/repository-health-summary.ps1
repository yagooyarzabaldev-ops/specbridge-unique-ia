# SpecBridge CLI library: repository-health-summary
# Dot-sourced by scripts/specbridge.ps1. Do not run directly.

function Build-RepositoryHealthSummary {
  $branchInventory   = Build-BranchInventory
  $branchPolicy      = Build-BranchCleanupPolicyEvaluation
  $artifactInventory = Build-ArtifactInventory
  $artifactPolicy    = Build-ArtifactRetentionPolicyEvaluation

  $branchCleanupBlocked     = [int] $branchPolicy.totals.blocked_count
  $artifactRetentionBlocked = [int] $artifactPolicy.totals.blocked_count
  $totalBlocked             = $branchCleanupBlocked + $artifactRetentionBlocked

  $overallHealthPosture = if ($totalBlocked -gt 0) {
    "debt_present_cleanup_blocked"
  } else {
    "stable_no_debt"
  }

  $futureGates = @($branchPolicy.required_future_gates + $artifactPolicy.required_future_gates | Sort-Object -Unique)

  $generatedAt = $null
  foreach ($candidate in @($branchInventory.generated_at, $artifactInventory.generated_at)) {
    if (-not [string]::IsNullOrWhiteSpace($candidate)) {
      if ($null -eq $generatedAt -or $candidate -gt $generatedAt) {
        $generatedAt = $candidate
      }
    }
  }

  return [ordered]@{
    command                 = "specbridge-repository-health-summary"
    generated_at            = $generatedAt
    overall_health_posture  = $overallHealthPosture
    branch_posture          = [ordered]@{
      total_refs                 = [int] $branchInventory.totals.total_refs
      local_branch_count         = [int] $branchInventory.totals.local_branch_count
      origin_branch_count        = [int] $branchInventory.totals.origin_branch_count
      merged_into_main_count     = [int] $branchInventory.totals.merged_into_main_count
      unmerged_into_main_count   = [int] $branchInventory.totals.unmerged_into_main_count
      unknown_merge_status_count = [int] $branchInventory.totals.unknown_merge_status_count
      branch_mutation_policy     = "none"
    }
    artifact_posture        = [ordered]@{
      family_count           = [int] $artifactInventory.totals.family_count
      total_file_count       = [int] $artifactInventory.totals.total_file_count
      total_bytes            = [long] $artifactInventory.totals.total_bytes
      retention_enforcement  = "none"
    }
    policy_posture           = [ordered]@{
      branch_cleanup_policy      = [ordered]@{
        policy_id          = [string] $branchPolicy.policy_metadata.policy_id
        status             = [string] $branchPolicy.policy_metadata.status
        enforcement        = [string] $branchPolicy.policy_metadata.enforcement
        cleanup_permission = [string] $branchPolicy.policy_metadata.cleanup_permission
      }
      artifact_retention_policy  = [ordered]@{
        policy_id          = [string] $artifactPolicy.policy_metadata.policy_id
        status             = [string] $artifactPolicy.policy_metadata.status
        enforcement        = [string] $artifactPolicy.policy_metadata.enforcement
        cleanup_permission = [string] $artifactPolicy.policy_metadata.cleanup_permission
      }
    }
    cleanup_permission       = "none"
    enforcement_status       = "none"
    blocked_action_counts    = [ordered]@{
      branch_cleanup_blocked     = $branchCleanupBlocked
      artifact_retention_blocked = $artifactRetentionBlocked
      total_blocked              = $totalBlocked
    }
    required_future_gates    = $futureGates
    evidence_sources         = @(
      [ordered]@{ evidence_id = "branch_inventory";          source_path = "scripts/lib/branch-inventory.ps1" }
      [ordered]@{ evidence_id = "branch_cleanup_policy";      source_path = "scripts/lib/branch-cleanup-policy.ps1" }
      [ordered]@{ evidence_id = "artifact_inventory";         source_path = "scripts/lib/artifact-inventory.ps1" }
      [ordered]@{ evidence_id = "artifact_retention_policy";  source_path = "scripts/lib/artifact-retention-policy.ps1" }
    )
    non_enforcement_note     = "This command does not enable, authorize, or perform branch cleanup or artifact retention enforcement. cleanup_permission and enforcement_status remain 'none' regardless of detected debt."
    read_only_note           = "This command does not delete, prune, rename, move, archive, compress, upload, fetch, pull, force-push, or otherwise mutate branches or artifacts. It only reads existing local evidence builders."
  }
}

function Invoke-RepositoryHealthSummaryCommand {
  $summary = Build-RepositoryHealthSummary

  if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $expectedPath = ".specbridge/repository-health/current.summary.json"
    $normalized = Normalize-RepoPath -Path $OutputPath -FieldName "OutputPath"
    if ($normalized -ne $expectedPath) {
      Fail "OutputPath must be $expectedPath`: $normalized"
    }
    $fullOutputPath = Join-Path $repoRoot $normalized
    if ((Test-Path -LiteralPath $fullOutputPath) -and -not $Force) {
      Fail "OutputPath already exists; use -Force to replace it: $normalized"
    }
    Write-Utf8JsonFile -Path $normalized -Value $summary -Depth 12
    Write-CliJson ([ordered]@{
      command     = "specbridge-repository-health-summary"
      ok          = $true
      output_path = $normalized
      summary     = $summary
    }) -Depth 12
    return
  }

  Write-CliJson ([ordered]@{
    command = "specbridge-repository-health-summary"
    ok      = $true
    summary = $summary
  }) -Depth 12
}
