# SpecBridge CLI library: artifact-retention-policy
# Dot-sourced by scripts/specbridge.ps1. Do not run directly.

function Get-ArtifactFamilyClass {
  param(
    [string] $FamilyId,
    [object] $PolicyFamilyClasses
  )

  if ($null -eq $PolicyFamilyClasses) {
    $defaultMap = @{
      contracts         = "evidence_primary"
      scopes            = "evidence_primary"
      reports           = "evidence_primary"
      audit_packets     = "evidence_primary"
      chatgpt_audits    = "evidence_primary"
      runtime_launches  = "evidence_runtime"
      runtime_preflights = "evidence_runtime"
      runtime_results   = "evidence_runtime"
      runtime_summaries = "evidence_runtime"
      runtime_runs      = "evidence_runtime"
      runtime_executions = "evidence_runtime"
      orchestrations    = "evidence_orchestration"
      executor_packets  = "evidence_orchestration"
      github_evidence   = "evidence_orchestration"
      ledger            = "evidence_ledger"
      mcp_resources     = "evidence_derived"
      artifact_inventory = "evidence_derived"
      branch_inventory  = "evidence_derived"
      branch_cleanup_policy = "evidence_derived"
      artifact_retention_policy = "evidence_derived"
    }
    if ($defaultMap.ContainsKey($FamilyId)) { return $defaultMap[$FamilyId] }
    return "evidence_unclassified"
  }

  foreach ($cls in @($PolicyFamilyClasses)) {
    if (@($cls.family_ids) -contains $FamilyId) { return [string] $cls.class_id }
  }
  return "evidence_unclassified"
}

function Get-ArtifactFamilyCleanupGate {
  param(
    [string] $FamilyClass,
    [object] $PolicyFamilyClasses
  )

  if ($null -eq $PolicyFamilyClasses) {
    $derivedClasses = @("evidence_derived", "evidence_unclassified")
    if ($derivedClasses -contains $FamilyClass) { return "activation_required" }
    return "blocked"
  }

  foreach ($cls in @($PolicyFamilyClasses)) {
    if ([string] $cls.class_id -eq $FamilyClass) {
      return [string] $cls.cleanup_gate
    }
  }
  return "blocked"
}

function Build-ArtifactRetentionPolicyEvaluation {
  $policyPath = Join-Path $repoRoot ".specbridge/policies/artifact-retention-policy.draft.json"
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
      policy_id          = "artifact-retention-policy"
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

  $policyFamilyClasses = if ($null -ne $policy -and $null -ne $policy.artifact_family_classes) {
    $policy.artifact_family_classes
  } else {
    $null
  }

  $inventory = Build-ArtifactInventory
  $families = @($inventory.families)

  $familyClassCounts = @{}
  $blockedCounts     = @{}
  $familyEvaluations = @()

  foreach ($fam in $families) {
    $famId    = [string] $fam.family_id
    $famClass = Get-ArtifactFamilyClass -FamilyId $famId -PolicyFamilyClasses $policyFamilyClasses
    $gate     = Get-ArtifactFamilyCleanupGate -FamilyClass $famClass -PolicyFamilyClasses $policyFamilyClasses

    if (-not $familyClassCounts.ContainsKey($famClass)) { $familyClassCounts[$famClass] = 0 }
    $familyClassCounts[$famClass] += 1

    if ($gate -eq "blocked") {
      if (-not $blockedCounts.ContainsKey($famClass)) { $blockedCounts[$famClass] = 0 }
      $blockedCounts[$famClass] += 1
    }

    $familyEvaluations += [ordered]@{
      family_id          = $famId
      repository_path    = [string] $fam.repository_path
      family_class       = $famClass
      file_count         = [long]   $fam.file_count
      total_bytes        = [long]   $fam.total_bytes
      cleanup_permission = "none"
      retention_posture  = "preserve"
      future_gate        = $gate
    }
  }

  $familyClassCountEntries = @()
  foreach ($cls in @($familyClassCounts.Keys | Sort-Object)) {
    $familyClassCountEntries += [ordered]@{ class = $cls; count = $familyClassCounts[$cls] }
  }

  $blockedCountEntries = @()
  foreach ($cls in @($blockedCounts.Keys | Sort-Object)) {
    $blockedCountEntries += [ordered]@{ class = $cls; count = $blockedCounts[$cls] }
  }

  $totalBlocked = 0
  foreach ($v in @($blockedCounts.Values)) { $totalBlocked += [int] $v }

  return [ordered]@{
    command               = "specbridge-artifact-retention-policy"
    policy_metadata       = $policyMetadata
    enforcement_status    = "none"
    totals                = [ordered]@{
      total_families = $families.Count
      evaluated      = $familyEvaluations.Count
      blocked_count  = $totalBlocked
    }
    family_class_counts   = $familyClassCountEntries
    blocked_counts        = $blockedCountEntries
    required_future_gates = $requiredFutureGates
    family_evaluations    = $familyEvaluations
    read_only_note        = "This command does not delete, archive, prune, compress, or move any artifacts. No retention enforcement or artifact cleanup is authorized."
  }
}

function Invoke-ArtifactRetentionPolicyCommand {
  $evaluation = Build-ArtifactRetentionPolicyEvaluation

  if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $expectedPath = ".specbridge/artifact-retention/current.policy-evaluation.json"
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
      command     = "specbridge-artifact-retention-policy"
      ok          = $true
      output_path = $normalized
      evaluation  = $evaluation
    }) -Depth 12
    return
  }

  Write-CliJson ([ordered]@{
    command    = "specbridge-artifact-retention-policy"
    ok         = $true
    evaluation = $evaluation
  }) -Depth 12
}
