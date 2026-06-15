# SpecBridge CLI library: branch-cleanup-policy
# Dot-sourced by scripts/specbridge.ps1. Do not run directly.

function Get-BranchCleanupCandidateClass {
  param(
    [string] $RefType,
    [object] $MergedIntoMain
  )

  if ($MergedIntoMain -eq $true -and $RefType -eq "local")  { return "merged_local"        }
  if ($MergedIntoMain -eq $true -and $RefType -eq "origin") { return "merged_origin"       }
  if ($MergedIntoMain -eq $false -and $RefType -eq "local") { return "unmerged_local"      }
  if ($MergedIntoMain -eq $false -and $RefType -eq "origin"){ return "unmerged_origin"     }
  return "unknown_merge_status"
}

function Build-BranchCleanupPolicyEvaluation {
  $policyPath = Join-Path $repoRoot ".specbridge/policies/branch-cleanup-policy.draft.json"
  $policy = $null
  if (Test-Path -LiteralPath $policyPath) {
    try {
      $raw = Get-Content -LiteralPath $policyPath -Raw -Encoding UTF8
      $policy = $raw | ConvertFrom-Json
    } catch {}
  }

  $policyMetadata = if ($null -ne $policy) {
    [ordered]@{
      policy_id          = [string] $policy.policy_id
      schema_version     = [int]    $policy.schema_version
      status             = [string] $policy.status
      enforcement        = [string] $policy.enforcement
      cleanup_permission = [string] $policy.cleanup_permission
    }
  } else {
    [ordered]@{
      policy_id          = "branch-cleanup-policy"
      schema_version     = 1
      status             = "draft"
      enforcement        = "none"
      cleanup_permission = "none"
    }
  }

  $requiredFutureGates = if ($null -ne $policy -and $null -ne $policy.required_gates) {
    @($policy.required_gates | ForEach-Object { [string] $_ })
  } else {
    @(
      "policy_status_must_be_active",
      "enforcement_must_not_be_none",
      "explicit_operator_authorization",
      "ci_must_pass",
      "review_gate_must_pass"
    )
  }

  $inventory = Build-BranchInventory
  $branches = @($inventory.branches)

  $candidateCounts   = @{}
  $blockedCounts     = @{}
  $branchEvaluations = @()

  foreach ($branch in $branches) {
    $class = Get-BranchCleanupCandidateClass `
      -RefType        $branch.ref_type `
      -MergedIntoMain $branch.merged_into_main

    if (-not $candidateCounts.ContainsKey($class)) { $candidateCounts[$class] = 0 }
    $candidateCounts[$class] += 1

    $futureGate = if ($class -eq "merged_local" -or $class -eq "merged_origin") {
      "activation_required"
    } else {
      "blocked"
    }

    if ($futureGate -eq "blocked") {
      if (-not $blockedCounts.ContainsKey($class)) { $blockedCounts[$class] = 0 }
      $blockedCounts[$class] += 1
    }

    $branchEvaluations += [ordered]@{
      ref_name           = [string] $branch.ref_name
      branch_name        = [string] $branch.branch_name
      ref_type           = [string] $branch.ref_type
      candidate_class    = $class
      cleanup_permission = "none"
      future_gate        = $futureGate
    }
  }

  $candidateCountEntries = @()
  foreach ($className in @($candidateCounts.Keys | Sort-Object)) {
    $candidateCountEntries += [ordered]@{ class = $className; count = $candidateCounts[$className] }
  }

  $blockedCountEntries = @()
  foreach ($className in @($blockedCounts.Keys | Sort-Object)) {
    $blockedCountEntries += [ordered]@{ class = $className; count = $blockedCounts[$className] }
  }

  $totalBlocked = 0
  foreach ($v in @($blockedCounts.Values)) { $totalBlocked += [int] $v }

  return [ordered]@{
    command               = "specbridge-branch-cleanup-policy"
    policy_metadata       = $policyMetadata
    enforcement_status    = "none"
    totals                = [ordered]@{
      total_refs    = $branches.Count
      evaluated     = $branchEvaluations.Count
      blocked_count = $totalBlocked
    }
    candidate_counts      = $candidateCountEntries
    blocked_counts        = $blockedCountEntries
    required_future_gates = $requiredFutureGates
    branch_evaluations    = $branchEvaluations
    read_only_note        = "This command does not delete, prune, rename, move, archive, fetch, pull, or force-push branches. No cleanup is authorized."
  }
}

function Invoke-BranchCleanupPolicyCommand {
  $evaluation = Build-BranchCleanupPolicyEvaluation

  if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $expectedPath = ".specbridge/branch-cleanup/current.policy-evaluation.json"
    $normalized = Normalize-RepoPath -Path $OutputPath -FieldName "OutputPath"
    if ($normalized -ne $expectedPath) {
      Fail "OutputPath must be $expectedPath`: $normalized"
    }
    $fullOutputPath = Join-Path $repoRoot $normalized
    if ((Test-Path -LiteralPath $fullOutputPath) -and -not $Force) {
      Fail "OutputPath already exists; use -Force to replace it: $normalized"
    }
    Write-Utf8JsonFile -Path $normalized -Value $evaluation -Depth 12
    Write-CliJson ([ordered]@{
      command     = "specbridge-branch-cleanup-policy"
      ok          = $true
      output_path = $normalized
      evaluation  = $evaluation
    }) -Depth 12
    return
  }

  Write-CliJson ([ordered]@{
    command    = "specbridge-branch-cleanup-policy"
    ok         = $true
    evaluation = $evaluation
  }) -Depth 12
}
