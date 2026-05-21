param(
  [string] $BranchPlansPath = ".specbridge/branch-plans",
  [string] $OrchestrationsPath = ".specbridge/orchestrations"
)

$ErrorActionPreference = "Stop"

Write-Output "SpecBridge branch orchestration validation started."

$failed = $false

$branchPlanRequiredFields = @(
  "schema_version",
  "plan_id",
  "task_id",
  "source_task_id",
  "generated_by",
  "repository_url",
  "base_branch",
  "source_packet_count",
  "executor_branches",
  "coordinator_gates",
  "status",
  "source_files"
)

$branchPlanAllowedFields = $branchPlanRequiredFields
$executorBranchRequiredFields = @(
  "packet_id",
  "slice_id",
  "agent_role",
  "branch_name",
  "base_branch",
  "execution_contract_path",
  "final_report_path",
  "exclusive_write",
  "required_validations",
  "pr_title",
  "pr_url",
  "pr_status",
  "ci_status",
  "chatgpt_audit_status",
  "merge_status",
  "rollback_notes"
)

$orchestrationRequiredFields = @(
  "schema_version",
  "orchestration_id",
  "task_id",
  "generated_by",
  "evidence_mode",
  "branch_plan_path",
  "repository_url",
  "base_branch",
  "child_results",
  "integration_decision",
  "coordinator_status",
  "required_next_evidence",
  "source_files"
)

$orchestrationAllowedFields = $orchestrationRequiredFields
$childResultRequiredFields = @(
  "packet_id",
  "slice_id",
  "agent_role",
  "branch_name",
  "pr_url",
  "pr_status",
  "ci_status",
  "chatgpt_audit_status",
  "merge_allowed",
  "merge_blocker",
  "rollback_notes"
)

$allowedPlanStatuses = @("planned", "evidence_recorded", "active", "completed", "blocked", "cancelled")
$allowedEvidenceModes = @("simulation", "github")
$allowedIntegrationDecisions = @("simulation_only_no_merge", "ready_for_integration", "blocked")
$allowedCoordinatorStatuses = @("simulated", "ready_for_integration", "blocked")

function Write-Failure {
  param(
    [string] $Message
  )

  Write-Output "FAIL $Message"
  $script:failed = $true
}

function Test-RequiredFields {
  param(
    [object] $Object,
    [string[]] $RequiredFields,
    [string[]] $AllowedFields,
    [string] $FileName
  )

  $propertyNames = @($Object.PSObject.Properties.Name)

  foreach ($requiredField in $RequiredFields) {
    if ($propertyNames -notcontains $requiredField) {
      Write-Failure "missing required field in $FileName`: $requiredField"
    }
  }

  foreach ($propertyName in $propertyNames) {
    if ($AllowedFields -notcontains $propertyName) {
      Write-Failure "unexpected field in $FileName`: $propertyName"
    }
  }
}

function Test-String {
  param(
    [AllowNull()]
    [object] $Value,
    [string] $FieldName,
    [string] $FileName,
    [bool] $AllowNull = $false
  )

  if ($AllowNull -and $null -eq $Value) {
    return
  }

  if ($null -eq $Value -or $Value.GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($Value)) {
    Write-Failure "$FieldName must be a non-empty string in $FileName"
  }
}

function Test-StringArray {
  param(
    [object] $Value,
    [string] $FieldName,
    [string] $FileName,
    [bool] $AllowEmpty = $false
  )

  if ($null -eq $Value -or -not ($Value -is [System.Array])) {
    Write-Failure "$FieldName must be an array in $FileName"
    return @()
  }

  $items = @($Value)

  if (-not $AllowEmpty -and $items.Count -le 0) {
    Write-Failure "$FieldName must not be empty in $FileName"
  }

  foreach ($item in $items) {
    if ($null -eq $item -or $item.GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($item)) {
      Write-Failure "$FieldName must contain only non-empty strings in $FileName"
    }
  }

  return @($items)
}

function Test-RepoPath {
  param(
    [AllowNull()]
    [object] $Path,
    [string] $FieldName,
    [string] $FileName,
    [bool] $MustExist = $false
  )

  if ($null -eq $Path -or $Path.GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($Path)) {
    Write-Failure "$FieldName must be a non-empty repository-relative path in $FileName"
    return
  }

  $normalized = $Path.Trim().Replace("\", "/")

  while ($normalized.StartsWith("./")) {
    $normalized = $normalized.Substring(2)
  }

  if ([System.IO.Path]::IsPathRooted($normalized)) {
    Write-Failure "$FieldName must be repository-relative in $FileName`: $Path"
  }

  if ($normalized -match "(^|/)\.\.(/|$)") {
    Write-Failure "$FieldName must not traverse parent directories in $FileName`: $Path"
  }

  if ($MustExist -and -not (Test-Path -LiteralPath $normalized)) {
    Write-Failure "$FieldName must reference an existing file in $FileName`: $normalized"
  }
}

function Test-BranchName {
  param(
    [object] $BranchName,
    [string] $FileName
  )

  Test-String -Value $BranchName -FieldName "branch_name" -FileName $FileName

  if ($null -ne $BranchName -and $BranchName -is [string]) {
    if ($BranchName -notmatch "^[A-Za-z0-9._/-]+$" -or $BranchName -match "(^|/)\.\.(/|$)") {
      Write-Failure "branch_name contains unsupported characters in $FileName`: $BranchName"
    }
  }
}

if (-not (Test-Path -LiteralPath $BranchPlansPath)) {
  Write-Output "FAIL missing branch plan directory: $BranchPlansPath"
  exit 1
}

if (-not (Test-Path -LiteralPath $OrchestrationsPath)) {
  Write-Output "FAIL missing executor orchestration directory: $OrchestrationsPath"
  exit 1
}

$branchPlanFiles = Get-ChildItem -LiteralPath $BranchPlansPath -Filter "*.branch-plan.json" -File
$orchestrationFiles = Get-ChildItem -LiteralPath $OrchestrationsPath -Filter "*.executor-orchestration.json" -File

if ($branchPlanFiles.Count -le 0) {
  Write-Output "FAIL no branch plan files found in $BranchPlansPath"
  exit 1
}

if ($orchestrationFiles.Count -le 0) {
  Write-Output "FAIL no executor orchestration files found in $OrchestrationsPath"
  exit 1
}

foreach ($file in $branchPlanFiles) {
  Write-Output "Validating branch plan: $($file.FullName)"

  try {
    $plan = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
  }
  catch {
    Write-Failure "invalid JSON in branch plan: $($file.FullName)"
    continue
  }

  Test-RequiredFields -Object $plan -RequiredFields $branchPlanRequiredFields -AllowedFields $branchPlanAllowedFields -FileName $file.FullName

  if ($plan.schema_version -ne "1") {
    Write-Failure "schema_version must be 1 in $($file.FullName)"
  }

  foreach ($stringField in @("plan_id", "task_id", "source_task_id", "generated_by", "repository_url", "base_branch", "status")) {
    if ($plan.PSObject.Properties.Name.Contains($stringField)) {
      Test-String -Value $plan.$stringField -FieldName $stringField -FileName $file.FullName
    }
  }

  if ($plan.status -and $allowedPlanStatuses -notcontains $plan.status) {
    Write-Failure "invalid branch plan status in $($file.FullName): $($plan.status)"
  }

  if ($plan.source_packet_count -isnot [int] -and $plan.source_packet_count -isnot [long]) {
    Write-Failure "source_packet_count must be an integer in $($file.FullName)"
  }

  if ($null -eq $plan.executor_branches -or -not ($plan.executor_branches -is [System.Array]) -or @($plan.executor_branches).Count -le 0) {
    Write-Failure "executor_branches must be a non-empty array in $($file.FullName)"
    continue
  }

  $executorBranches = @($plan.executor_branches)

  if ($plan.source_packet_count -ne $executorBranches.Count) {
    Write-Failure "source_packet_count must match executor_branches count in $($file.FullName)"
  }

  foreach ($path in (Test-StringArray -Value $plan.source_files -FieldName "source_files" -FileName $file.FullName)) {
    Test-RepoPath -Path $path -FieldName "source_files" -FileName $file.FullName -MustExist $true

    if ($path -notmatch "^\.specbridge/executor-packets/.+\.executor-packet\.json$" -and
        $path -notmatch "^\.specbridge/branch-plans/.+\.branch-plan\.json$" -and
        $path -notmatch "^\.specbridge/github-evidence/.+\.json$") {
      Write-Failure "source_files must reference executor packets, branch plans, or GitHub evidence in $($file.FullName): $path"
    }
  }

  $packetIds = @{}
  $branchNames = @{}

  foreach ($executor in $executorBranches) {
    Test-RequiredFields -Object $executor -RequiredFields $executorBranchRequiredFields -AllowedFields $executorBranchRequiredFields -FileName $file.FullName

    foreach ($stringField in @("packet_id", "slice_id", "agent_role", "branch_name", "base_branch", "execution_contract_path", "final_report_path", "pr_title", "pr_status", "ci_status", "chatgpt_audit_status", "merge_status")) {
      if ($executor.PSObject.Properties.Name.Contains($stringField)) {
        Test-String -Value $executor.$stringField -FieldName $stringField -FileName $file.FullName
      }
    }

    Test-String -Value $executor.pr_url -FieldName "pr_url" -FileName $file.FullName -AllowNull $true

    if ($null -ne $executor.pr_url -and $executor.pr_url -notmatch "^(https://github\.com/.+/.+/pull/[0-9]+|simulation://pull-requests/.+)$") {
      Write-Failure "pr_url must be null, a GitHub PR URL, or a simulation URL in $($file.FullName): $($executor.pr_url)"
    }

    if ($plan.status -eq "evidence_recorded") {
      if ($null -eq $executor.pr_url -or $executor.pr_url -notmatch "^https://github\.com/.+/.+/pull/[0-9]+$") {
        Write-Failure "evidence_recorded branch plan requires a GitHub PR URL in $($file.FullName): packet=$($executor.packet_id)"
      }

      if ($executor.ci_status -eq "not_collected" -or $executor.chatgpt_audit_status -eq "not_collected") {
        Write-Failure "evidence_recorded branch plan requires collected CI and audit status in $($file.FullName): packet=$($executor.packet_id)"
      }
    }

    Test-BranchName -BranchName $executor.branch_name -FileName $file.FullName

    if ($packetIds.ContainsKey($executor.packet_id)) {
      Write-Failure "duplicate packet_id in branch plan: $($executor.packet_id)"
    }
    else {
      $packetIds[$executor.packet_id] = $true
    }

    if ($branchNames.ContainsKey($executor.branch_name)) {
      Write-Failure "duplicate branch_name in branch plan: $($executor.branch_name)"
    }
    else {
      $branchNames[$executor.branch_name] = $true
    }

    Test-RepoPath -Path $executor.execution_contract_path -FieldName "execution_contract_path" -FileName $file.FullName -MustExist $true

    if ($executor.execution_contract_path -notmatch "^\.specbridge/contracts/.+\.execution\.md$") {
      Write-Failure "execution_contract_path must point to a contract in $($file.FullName): $($executor.execution_contract_path)"
    }

    Test-RepoPath -Path $executor.final_report_path -FieldName "final_report_path" -FileName $file.FullName

    if ($executor.final_report_path -notmatch "^\.specbridge/reports/.+\.final-report\.json$") {
      Write-Failure "final_report_path must point to a final report path in $($file.FullName): $($executor.final_report_path)"
    }

    foreach ($path in (Test-StringArray -Value $executor.exclusive_write -FieldName "exclusive_write" -FileName $file.FullName)) {
      Test-RepoPath -Path $path -FieldName "exclusive_write" -FileName $file.FullName
    }

    [void] (Test-StringArray -Value $executor.required_validations -FieldName "required_validations" -FileName $file.FullName)
    [void] (Test-StringArray -Value $executor.rollback_notes -FieldName "rollback_notes" -FileName $file.FullName)
  }
}

foreach ($file in $orchestrationFiles) {
  Write-Output "Validating executor orchestration: $($file.FullName)"

  try {
    $orchestration = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
  }
  catch {
    Write-Failure "invalid JSON in executor orchestration: $($file.FullName)"
    continue
  }

  Test-RequiredFields -Object $orchestration -RequiredFields $orchestrationRequiredFields -AllowedFields $orchestrationAllowedFields -FileName $file.FullName

  if ($orchestration.schema_version -ne "1") {
    Write-Failure "schema_version must be 1 in $($file.FullName)"
  }

  foreach ($stringField in @("orchestration_id", "task_id", "generated_by", "evidence_mode", "branch_plan_path", "repository_url", "base_branch", "integration_decision", "coordinator_status")) {
    if ($orchestration.PSObject.Properties.Name.Contains($stringField)) {
      Test-String -Value $orchestration.$stringField -FieldName $stringField -FileName $file.FullName
    }
  }

  if ($allowedEvidenceModes -notcontains $orchestration.evidence_mode) {
    Write-Failure "invalid evidence_mode in $($file.FullName): $($orchestration.evidence_mode)"
  }

  if ($allowedIntegrationDecisions -notcontains $orchestration.integration_decision) {
    Write-Failure "invalid integration_decision in $($file.FullName): $($orchestration.integration_decision)"
  }

  if ($allowedCoordinatorStatuses -notcontains $orchestration.coordinator_status) {
    Write-Failure "invalid coordinator_status in $($file.FullName): $($orchestration.coordinator_status)"
  }

  Test-RepoPath -Path $orchestration.branch_plan_path -FieldName "branch_plan_path" -FileName $file.FullName -MustExist $true

  if ($orchestration.branch_plan_path -notmatch "^\.specbridge/branch-plans/.+\.branch-plan\.json$") {
    Write-Failure "branch_plan_path must point to a branch plan in $($file.FullName): $($orchestration.branch_plan_path)"
  }

  foreach ($path in (Test-StringArray -Value $orchestration.source_files -FieldName "source_files" -FileName $file.FullName)) {
    Test-RepoPath -Path $path -FieldName "source_files" -FileName $file.FullName -MustExist $true
  }

  [void] (Test-StringArray -Value $orchestration.required_next_evidence -FieldName "required_next_evidence" -FileName $file.FullName -AllowEmpty ($orchestration.evidence_mode -eq "github"))

  if ($null -eq $orchestration.child_results -or -not ($orchestration.child_results -is [System.Array]) -or @($orchestration.child_results).Count -le 0) {
    Write-Failure "child_results must be a non-empty array in $($file.FullName)"
    continue
  }

  foreach ($child in @($orchestration.child_results)) {
    Test-RequiredFields -Object $child -RequiredFields $childResultRequiredFields -AllowedFields $childResultRequiredFields -FileName $file.FullName

    foreach ($stringField in @("packet_id", "slice_id", "agent_role", "branch_name", "pr_url", "pr_status", "ci_status", "chatgpt_audit_status")) {
      if ($child.PSObject.Properties.Name.Contains($stringField)) {
        Test-String -Value $child.$stringField -FieldName $stringField -FileName $file.FullName
      }
    }

    if ($child.merge_allowed -eq $false) {
      Test-String -Value $child.merge_blocker -FieldName "merge_blocker" -FileName $file.FullName
    }

    Test-BranchName -BranchName $child.branch_name -FileName $file.FullName

    if ($child.merge_allowed -isnot [bool]) {
      Write-Failure "merge_allowed must be boolean in $($file.FullName): packet=$($child.packet_id)"
    }

    [void] (Test-StringArray -Value $child.rollback_notes -FieldName "rollback_notes" -FileName $file.FullName)

    if ($orchestration.evidence_mode -eq "simulation") {
      if ($child.pr_url -notmatch "^simulation://pull-requests/.+") {
        Write-Failure "simulation child result must use simulation PR URL in $($file.FullName): packet=$($child.packet_id)"
      }

      if ($child.ci_status -ne "simulated_passed" -or $child.chatgpt_audit_status -ne "simulated_approved") {
        Write-Failure "simulation child result must mark simulated CI and audit evidence in $($file.FullName): packet=$($child.packet_id)"
      }

      if ($child.merge_allowed -ne $false) {
        Write-Failure "simulation child result cannot allow merge in $($file.FullName): packet=$($child.packet_id)"
      }
    }

    if ($orchestration.evidence_mode -eq "github" -and $child.pr_url -notmatch "^https://github\.com/.+/.+/pull/[0-9]+$") {
      Write-Failure "github child result must use a GitHub PR URL in $($file.FullName): packet=$($child.packet_id)"
    }

    if ($orchestration.evidence_mode -eq "github" -and $child.merge_allowed -eq $true) {
      if ($child.ci_status -ne "passed" -or $child.chatgpt_audit_status -ne "approved") {
        Write-Failure "github child result can allow merge only with passed CI and approved audit in $($file.FullName): packet=$($child.packet_id)"
      }
    }
  }

  if ($orchestration.evidence_mode -eq "simulation" -and $orchestration.integration_decision -ne "simulation_only_no_merge") {
    Write-Failure "simulation orchestration must use integration_decision simulation_only_no_merge in $($file.FullName)"
  }

  if ($orchestration.evidence_mode -eq "github" -and $orchestration.integration_decision -eq "ready_for_integration") {
    $notReadyChildren = @(
      $orchestration.child_results |
        Where-Object {
          $_.merge_allowed -ne $true -or
          $_.ci_status -ne "passed" -or
          $_.chatgpt_audit_status -ne "approved"
        }
    )

    if ($notReadyChildren.Count -gt 0) {
      Write-Failure "ready_for_integration requires every github child result to be merge_allowed with passed CI and approved audit in $($file.FullName)"
    }
  }
}

if ($failed) {
  Write-Output "SpecBridge branch orchestration validation failed."
  exit 1
}

Write-Output "SpecBridge branch orchestration validation passed."
exit 0
