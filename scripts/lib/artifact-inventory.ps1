# SpecBridge CLI library: artifact-inventory
# Dot-sourced by scripts/specbridge.ps1. Do not run directly.

function Get-FamilyInventory {
  param(
    [string] $FamilyId,
    [string] $RepoPath
  )

  $fullPath = Join-Path $repoRoot $RepoPath
  $fileCount = 0
  [long] $totalBytes = 0
  $latestModified = $null

  if (Test-Path -LiteralPath $fullPath) {
    $files = @(Get-ChildItem -LiteralPath $fullPath -File -Recurse -ErrorAction SilentlyContinue)
    $fileCount = $files.Count
    $sumResult = $files | Measure-Object -Property Length -Sum
    if ($null -ne $sumResult.Sum) {
      $totalBytes = [long] $sumResult.Sum
    }
    $latest = $files | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
    if ($null -ne $latest) {
      $latestModified = $latest.LastWriteTimeUtc.ToString("o")
    }
  }

  return [ordered]@{
    family_id          = $FamilyId
    repository_path    = $RepoPath
    file_count         = $fileCount
    total_bytes        = $totalBytes
    latest_modified    = $latestModified
    retention_posture  = "preserve"
    cleanup_permission = "none"
  }
}

function Build-ArtifactInventory {
  $families = @(
    (Get-FamilyInventory -FamilyId "contracts"           -RepoPath ".specbridge/contracts"),
    (Get-FamilyInventory -FamilyId "scopes"              -RepoPath ".specbridge/scopes"),
    (Get-FamilyInventory -FamilyId "reports"             -RepoPath ".specbridge/reports"),
    (Get-FamilyInventory -FamilyId "audit_packets"       -RepoPath ".specbridge/audit-packets"),
    (Get-FamilyInventory -FamilyId "chatgpt_audits"      -RepoPath ".specbridge/audits"),
    (Get-FamilyInventory -FamilyId "runtime_launches"    -RepoPath ".specbridge/runtime-launches"),
    (Get-FamilyInventory -FamilyId "runtime_preflights"  -RepoPath ".specbridge/preflights"),
    (Get-FamilyInventory -FamilyId "runtime_results"     -RepoPath ".specbridge/runtime-results"),
    (Get-FamilyInventory -FamilyId "runtime_summaries"   -RepoPath ".specbridge/runtime-summaries"),
    (Get-FamilyInventory -FamilyId "runtime_runs"        -RepoPath ".specbridge/runtime-runs"),
    (Get-FamilyInventory -FamilyId "runtime_executions"  -RepoPath ".specbridge/runtime-executions"),
    (Get-FamilyInventory -FamilyId "orchestrations"      -RepoPath ".specbridge/orchestrations"),
    (Get-FamilyInventory -FamilyId "executor_packets"    -RepoPath ".specbridge/executor-packets"),
    (Get-FamilyInventory -FamilyId "github_evidence"     -RepoPath ".specbridge/github-evidence"),
    (Get-FamilyInventory -FamilyId "ledger"              -RepoPath ".specbridge/ledger"),
    (Get-FamilyInventory -FamilyId "mcp_resources"       -RepoPath ".specbridge/mcp-resources"),
    (Get-FamilyInventory -FamilyId "artifact_inventory"  -RepoPath ".specbridge/artifact-inventory"),
    (Get-FamilyInventory -FamilyId "branch_inventory"    -RepoPath ".specbridge/branch-inventory"),
    (Get-FamilyInventory -FamilyId "branch_cleanup_policy"      -RepoPath ".specbridge/branch-cleanup"),
    (Get-FamilyInventory -FamilyId "artifact_retention_policy"  -RepoPath ".specbridge/artifact-retention")
  )

  [long] $totalFileCount = 0
  [long] $totalBytesAll  = 0
  $latestInventoryTimestamp = $null
  foreach ($fam in $families) {
    $totalFileCount += [long] $fam.file_count
    $totalBytesAll  += [long] $fam.total_bytes

    if (-not [string]::IsNullOrWhiteSpace($fam.latest_modified)) {
      if ($null -eq $latestInventoryTimestamp -or $fam.latest_modified -gt $latestInventoryTimestamp) {
        $latestInventoryTimestamp = $fam.latest_modified
      }
    }
  }

  return [ordered]@{
    command              = "specbridge-artifact-inventory"
    generated_at         = $latestInventoryTimestamp
    families             = $families
    totals               = [ordered]@{
      family_count      = $families.Count
      total_file_count  = $totalFileCount
      total_bytes       = $totalBytesAll
    }
    retention_enforcement = "none"
    read_only_note        = "This command does not delete, archive, prune, compress, or move any artifacts."
  }
}

function Invoke-ArtifactInventoryCommand {
  $inventory = Build-ArtifactInventory

  if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $expectedPath = ".specbridge/artifact-inventory/current.inventory.json"
    $normalized = Normalize-RepoPath -Path $OutputPath -FieldName "OutputPath"
    if ($normalized -ne $expectedPath) {
      Fail "OutputPath must be $expectedPath`: $normalized"
    }
    $fullOutputPath = Join-Path $repoRoot $normalized
    if ((Test-Path -LiteralPath $fullOutputPath) -and -not $Force) {
      Fail "OutputPath already exists; use -Force to replace it: $normalized"
    }
    Write-Utf8JsonFile -Path $normalized -Value $inventory -Depth 10
    Write-CliJson ([ordered]@{
      command     = "specbridge-artifact-inventory"
      ok          = $true
      output_path = $normalized
      inventory   = $inventory
    })
    return
  }

  Write-CliJson ([ordered]@{
    command   = "specbridge-artifact-inventory"
    ok        = $true
    inventory = $inventory
  })
}
