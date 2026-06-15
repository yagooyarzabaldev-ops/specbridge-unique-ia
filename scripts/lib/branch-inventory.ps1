# SpecBridge CLI library: branch-inventory
# Dot-sourced by scripts/specbridge.ps1. Do not run directly.

function Get-BranchInventoryPrefix {
  param(
    [string] $BranchName
  )

  if ([string]::IsNullOrWhiteSpace($BranchName)) {
    return "unknown"
  }

  $parts = @($BranchName.Split("/"))
  if ($parts.Count -le 1) {
    return $BranchName
  }

  return $parts[0]
}

function Test-GitRefExists {
  param(
    [string] $RefName
  )

  & git rev-parse --verify --quiet $RefName *> $null
  return ($LASTEXITCODE -eq 0)
}

function Test-BranchMergedIntoBase {
  param(
    [string] $RefName,
    [string] $BaseRef
  )

  if ([string]::IsNullOrWhiteSpace($BaseRef)) {
    return $null
  }

  & git merge-base --is-ancestor $RefName $BaseRef 2>$null
  $exitCode = $LASTEXITCODE

  if ($exitCode -eq 0) {
    return $true
  }

  if ($exitCode -eq 1) {
    return $false
  }

  return $null
}

function Build-BranchInventory {
  $baseRef = $null
  if (Test-GitRefExists -RefName "refs/remotes/origin/main") {
    $baseRef = "refs/remotes/origin/main"
  } elseif (Test-GitRefExists -RefName "refs/heads/main") {
    $baseRef = "refs/heads/main"
  }

  $currentBranch = (& git branch --show-current 2>$null | Select-Object -First 1)
  if ($null -eq $currentBranch) {
    $currentBranch = ""
  }
  $currentBranch = $currentBranch.ToString().Trim()

  $format = "%(refname)%09%(objectname)%09%(committerdate:iso-strict)"
  $lines = @(& git for-each-ref refs/heads refs/remotes/origin "--format=$format" 2>$null)
  if ($LASTEXITCODE -ne 0) {
    $lines = @()
  }

  $branches = @()
  foreach ($line in $lines) {
    if ([string]::IsNullOrWhiteSpace($line)) {
      continue
    }

    $parts = @($line.ToString().Split("`t"))
    if ($parts.Count -lt 3) {
      continue
    }

    $refName = $parts[0]
    $objectId = $parts[1]
    $commitTimestamp = $parts[2]

    if ($refName -eq "refs/remotes/origin/HEAD") {
      continue
    }

    $refType = "unknown"
    $shortName = $refName
    if ($refName.StartsWith("refs/heads/")) {
      $refType = "local"
      $shortName = $refName.Substring("refs/heads/".Length)
    } elseif ($refName.StartsWith("refs/remotes/origin/")) {
      $refType = "origin"
      $shortName = $refName.Substring("refs/remotes/origin/".Length)
    }

    $prefix = Get-BranchInventoryPrefix -BranchName $shortName
    $mergedIntoMain = Test-BranchMergedIntoBase -RefName $refName -BaseRef $baseRef

    $branches += [ordered]@{
      ref_name            = $refName
      branch_name         = $shortName
      ref_type            = $refType
      object_id           = $objectId
      latest_commit_at    = $commitTimestamp
      prefix              = $prefix
      merged_into_main    = $mergedIntoMain
      retention_posture   = "preserve"
      cleanup_permission  = "none"
    }
  }

  $branches = @($branches | Sort-Object @{ Expression = "ref_type"; Ascending = $true }, @{ Expression = "branch_name"; Ascending = $true })

  $prefixCounts = @{}
  foreach ($branch in $branches) {
    if (-not $prefixCounts.ContainsKey($branch.prefix)) {
      $prefixCounts[$branch.prefix] = 0
    }
    $prefixCounts[$branch.prefix] += 1
  }

  $prefixCountEntries = @()
  foreach ($prefix in @($prefixCounts.Keys | Sort-Object)) {
    $prefixCountEntries += [ordered]@{
      prefix = $prefix
      count  = $prefixCounts[$prefix]
    }
  }

  $latestInventoryTimestamp = $null
  foreach ($branch in $branches) {
    if (-not [string]::IsNullOrWhiteSpace($branch.latest_commit_at)) {
      if ($null -eq $latestInventoryTimestamp -or $branch.latest_commit_at -gt $latestInventoryTimestamp) {
        $latestInventoryTimestamp = $branch.latest_commit_at
      }
    }
  }

  $localBranchCount = @($branches | Where-Object { $_.ref_type -eq "local" }).Count
  $originBranchCount = @($branches | Where-Object { $_.ref_type -eq "origin" }).Count
  $mergedBranchCount = @($branches | Where-Object { $_.merged_into_main -eq $true }).Count
  $unmergedBranchCount = @($branches | Where-Object { $_.merged_into_main -eq $false }).Count
  $unknownMergeBranchCount = @($branches | Where-Object { $null -eq $_.merged_into_main }).Count

  return [ordered]@{
    command                = "specbridge-branch-inventory"
    generated_at           = $latestInventoryTimestamp
    base_ref               = $baseRef
    current_branch         = $currentBranch
    branches               = $branches
    totals                 = [ordered]@{
      total_refs                 = $branches.Count
      local_branch_count         = $localBranchCount
      origin_branch_count        = $originBranchCount
      merged_into_main_count     = $mergedBranchCount
      unmerged_into_main_count   = $unmergedBranchCount
      unknown_merge_status_count = $unknownMergeBranchCount
    }
    prefix_counts          = $prefixCountEntries
    branch_mutation_policy = "none"
    read_only_note         = "This command does not delete, prune, rename, move, archive, fetch, pull, or force-push branches."
  }
}

function Invoke-BranchInventoryCommand {
  $inventory = Build-BranchInventory

  if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $expectedPath = ".specbridge/branch-inventory/current.inventory.json"
    $normalized = Normalize-RepoPath -Path $OutputPath -FieldName "OutputPath"
    if ($normalized -ne $expectedPath) {
      Fail "OutputPath must be $expectedPath`: $normalized"
    }
    $fullOutputPath = Join-Path $repoRoot $normalized
    if ((Test-Path -LiteralPath $fullOutputPath) -and -not $Force) {
      Fail "OutputPath already exists; use -Force to replace it: $normalized"
    }
    Write-Utf8JsonFile -Path $normalized -Value $inventory -Depth 12
    Write-CliJson ([ordered]@{
      command     = "specbridge-branch-inventory"
      ok          = $true
      output_path = $normalized
      inventory   = $inventory
    }) -Depth 12
    return
  }

  Write-CliJson ([ordered]@{
    command   = "specbridge-branch-inventory"
    ok        = $true
    inventory = $inventory
  }) -Depth 12
}
