param(
  [string] $RuntimeSummariesPath = ".specbridge/runtime-summaries"
)

$ErrorActionPreference = "Stop"

Write-Output "SpecBridge runtime summary validation started."

$failed = $false

$requiredFields = @(
  "schema_version",
  "summary_id",
  "generated_by",
  "runtime_launch_path",
  "runtime_result_path",
  "launch_id",
  "task_id",
  "packet_id",
  "slice_id",
  "branch_name",
  "completion_status",
  "runtime_status",
  "result_status",
  "validation_totals",
  "policy_result",
  "merge_readiness",
  "blockers",
  "execution_policy",
  "source_files"
)

$allowedFields = $requiredFields
$allowedMergeReadiness = @("ready_for_policy_gates", "blocked")

function Write-Failure {
  param(
    [string] $Message
  )

  Write-Output "FAIL $Message"
  $script:failed = $true
}

function Normalize-RepoPath {
  param(
    [string] $Path
  )

  return $Path.Trim().Replace("\", "/")
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

  $normalizedPath = Normalize-RepoPath -Path $Path

  if ([System.IO.Path]::IsPathRooted($normalizedPath)) {
    Write-Failure "$FieldName must be repository-relative in $FileName`: $Path"
  }

  if ($normalizedPath -match "(^|/)\.\.(/|$)") {
    Write-Failure "$FieldName must not traverse parent directories in $FileName`: $Path"
  }

  if ($MustExist -and -not (Test-Path $normalizedPath -PathType Leaf)) {
    Write-Failure "$FieldName must reference an existing file in $FileName`: $normalizedPath"
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

function Test-RequiredBooleanPolicy {
  param(
    [object] $Policy,
    [string] $FieldName,
    [string] $FileName
  )

  if (-not $Policy.PSObject.Properties.Name.Contains($FieldName)) {
    Write-Failure "execution_policy missing $FieldName in $FileName"
    return
  }

  if ($Policy.$FieldName -isnot [bool]) {
    Write-Failure "execution_policy.$FieldName must be boolean in $FileName"
    return
  }

  if ($Policy.$FieldName -ne $false) {
    Write-Failure "execution_policy.$FieldName must be false in runtime summaries: $FileName"
  }
}

function Read-JsonFile {
  param(
    [string] $Path,
    [string] $Description
  )

  try {
    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
  }
  catch {
    Write-Failure "$Description must contain valid JSON: $Path"
    return $null
  }
}

function Test-IntegerField {
  param(
    [object] $Object,
    [string] $FieldName,
    [string] $FileName
  )

  if (-not $Object.PSObject.Properties.Name.Contains($FieldName)) {
    Write-Failure "validation_totals missing $FieldName in $FileName"
    return 0
  }

  $value = $Object.$FieldName

  if ($value -isnot [int] -and $value -isnot [long]) {
    Write-Failure "validation_totals.$FieldName must be an integer in $FileName"
    return 0
  }

  if ($value -lt 0) {
    Write-Failure "validation_totals.$FieldName must not be negative in $FileName"
  }

  return [int] $value
}

if (-not (Test-Path $RuntimeSummariesPath)) {
  Write-Output "FAIL missing runtime summaries directory: $RuntimeSummariesPath"
  exit 1
}

$summaryFiles = Get-ChildItem $RuntimeSummariesPath -Filter "*.runtime-summary.json" -File

if ($summaryFiles.Count -le 0) {
  Write-Output "FAIL no runtime summary files found in $RuntimeSummariesPath"
  exit 1
}

foreach ($file in $summaryFiles) {
  Write-Output "Validating runtime summary: $($file.FullName)"

  $summary = Read-JsonFile -Path $file.FullName -Description "runtime summary"

  if ($null -eq $summary) {
    continue
  }

  $propertyNames = @($summary.PSObject.Properties.Name)

  foreach ($requiredField in $requiredFields) {
    if ($propertyNames -notcontains $requiredField) {
      Write-Failure "missing required field in $($file.FullName): $requiredField"
    }
  }

  foreach ($propertyName in $propertyNames) {
    if ($allowedFields -notcontains $propertyName) {
      Write-Failure "unexpected field in $($file.FullName): $propertyName"
    }
  }

  if ($summary.schema_version -ne "1") {
    Write-Failure "schema_version must be 1 in $($file.FullName)"
  }

  foreach ($stringField in @("summary_id", "generated_by", "launch_id", "task_id", "packet_id", "slice_id", "branch_name", "completion_status", "runtime_status", "result_status", "policy_result", "merge_readiness")) {
    if ($propertyNames -contains $stringField) {
      $value = $summary.$stringField

      if ($null -eq $value -or $value.GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($value)) {
        Write-Failure "$stringField must be a non-empty string in $($file.FullName)"
      }
    }
  }

  if ($propertyNames -contains "merge_readiness" -and $allowedMergeReadiness -notcontains $summary.merge_readiness) {
    Write-Failure "merge_readiness is not allowed in $($file.FullName): $($summary.merge_readiness)"
  }

  if ($propertyNames -contains "runtime_launch_path") {
    Test-RepoPath -Path $summary.runtime_launch_path -FieldName "runtime_launch_path" -FileName $file.FullName -MustExist $true

    if ($summary.runtime_launch_path -notmatch "^\.specbridge/runtime-launches/.+\.runtime-launch\.json$") {
      Write-Failure "runtime_launch_path must point to a runtime launch in $($file.FullName): $($summary.runtime_launch_path)"
    }
  }

  if ($propertyNames -contains "runtime_result_path") {
    Test-RepoPath -Path $summary.runtime_result_path -FieldName "runtime_result_path" -FileName $file.FullName -MustExist $true

    if ($summary.runtime_result_path -notmatch "^\.specbridge/runtime-results/.+\.runtime-result\.json$") {
      Write-Failure "runtime_result_path must point to a runtime result in $($file.FullName): $($summary.runtime_result_path)"
    }
  }

  $blockers = @()

  if ($propertyNames -contains "blockers") {
    $blockers = Test-StringArray -Value $summary.blockers -FieldName "blockers" -FileName $file.FullName -AllowEmpty $true
  }

  if ($summary.merge_readiness -eq "blocked" -and $blockers.Count -le 0) {
    Write-Failure "blocked runtime summaries must include blockers in $($file.FullName)"
  }

  if ($summary.merge_readiness -eq "ready_for_policy_gates" -and $blockers.Count -gt 0) {
    Write-Failure "ready runtime summaries must not include blockers in $($file.FullName)"
  }

  $sourceFiles = @()

  if ($propertyNames -contains "source_files") {
    $sourceFiles = Test-StringArray -Value $summary.source_files -FieldName "source_files" -FileName $file.FullName

    foreach ($path in $sourceFiles) {
      Test-RepoPath -Path $path -FieldName "source_files" -FileName $file.FullName -MustExist $true
    }
  }

  foreach ($requiredSourceFile in @($summary.runtime_launch_path, $summary.runtime_result_path)) {
    if (-not [string]::IsNullOrWhiteSpace($requiredSourceFile) -and $sourceFiles -notcontains $requiredSourceFile) {
      Write-Failure "source_files must include referenced source path in $($file.FullName): $requiredSourceFile"
    }
  }

  if ($propertyNames -contains "validation_totals") {
    if ($null -eq $summary.validation_totals -or $summary.validation_totals.GetType().Name -notmatch "Object") {
      Write-Failure "validation_totals must be an object in $($file.FullName)"
    }
    else {
      $total = Test-IntegerField -Object $summary.validation_totals -FieldName "total" -FileName $file.FullName
      $passed = Test-IntegerField -Object $summary.validation_totals -FieldName "passed" -FileName $file.FullName
      $failedCount = Test-IntegerField -Object $summary.validation_totals -FieldName "failed" -FileName $file.FullName
      $other = Test-IntegerField -Object $summary.validation_totals -FieldName "other" -FileName $file.FullName

      if ($total -ne ($passed + $failedCount + $other)) {
        Write-Failure "validation_totals.total must equal passed + failed + other in $($file.FullName)"
      }
    }
  }

  if ($propertyNames -contains "execution_policy") {
    if ($null -eq $summary.execution_policy -or $summary.execution_policy.GetType().Name -notmatch "Object") {
      Write-Failure "execution_policy must be an object in $($file.FullName)"
    }
    else {
      foreach ($policyField in @("launches_claude", "launches_antigravity", "executes_shell", "requires_network", "touches_secrets", "touches_production", "installs_dependencies", "deploys")) {
        Test-RequiredBooleanPolicy -Policy $summary.execution_policy -FieldName $policyField -FileName $file.FullName
      }
    }
  }

  $launch = $null
  $result = $null

  if ($propertyNames -contains "runtime_launch_path" -and (Test-Path $summary.runtime_launch_path -PathType Leaf)) {
    $launch = Read-JsonFile -Path $summary.runtime_launch_path -Description "runtime launch"
  }

  if ($propertyNames -contains "runtime_result_path" -and (Test-Path $summary.runtime_result_path -PathType Leaf)) {
    $result = Read-JsonFile -Path $summary.runtime_result_path -Description "runtime result"
  }

  if ($null -ne $launch -and $null -ne $result) {
    if ($result.source_runtime_launch_path -ne $summary.runtime_launch_path) {
      Write-Failure "runtime result source_runtime_launch_path must match summary runtime_launch_path in $($file.FullName)"
    }

    foreach ($matchingField in @("launch_id", "task_id", "packet_id", "slice_id", "branch_name")) {
      if ($launch.PSObject.Properties.Name.Contains($matchingField) -and $summary.PSObject.Properties.Name.Contains($matchingField) -and $summary.$matchingField -ne $launch.$matchingField) {
        Write-Failure "$matchingField must match runtime launch in $($file.FullName)"
      }

      if ($result.PSObject.Properties.Name.Contains($matchingField) -and $summary.PSObject.Properties.Name.Contains($matchingField) -and $summary.$matchingField -ne $result.$matchingField) {
        Write-Failure "$matchingField must match runtime result in $($file.FullName)"
      }
    }

    foreach ($matchingField in @("completion_status", "runtime_status", "result_status", "policy_result")) {
      if ($result.PSObject.Properties.Name.Contains($matchingField) -and $summary.PSObject.Properties.Name.Contains($matchingField) -and $summary.$matchingField -ne $result.$matchingField) {
        Write-Failure "$matchingField must match runtime result in $($file.FullName)"
      }
    }

    $resultValidations = @($result.validation_results)
    $resultTotal = $resultValidations.Count
    $resultPassed = @($resultValidations | Where-Object { $_.result -eq "passed" }).Count
    $resultFailed = @($resultValidations | Where-Object { $_.result -eq "failed" }).Count
    $resultOther = $resultTotal - $resultPassed - $resultFailed

    if ($summary.validation_totals.total -ne $resultTotal -or
        $summary.validation_totals.passed -ne $resultPassed -or
        $summary.validation_totals.failed -ne $resultFailed -or
        $summary.validation_totals.other -ne $resultOther) {
      Write-Failure "validation_totals must match runtime result validation_results in $($file.FullName)"
    }

    $shouldBeReady = (
      $summary.runtime_status -eq "succeeded" -and
      $summary.result_status -eq "recorded" -and
      $summary.completion_status -eq "complete" -and
      $summary.validation_totals.failed -eq 0 -and
      $summary.validation_totals.other -eq 0 -and
      -not [string]::IsNullOrWhiteSpace($summary.policy_result)
    )

    if ($shouldBeReady -and $summary.merge_readiness -ne "ready_for_policy_gates") {
      Write-Failure "merge_readiness must be ready_for_policy_gates when runtime evidence is complete in $($file.FullName)"
    }

    if (-not $shouldBeReady -and $summary.merge_readiness -ne "blocked") {
      Write-Failure "merge_readiness must be blocked when runtime evidence is incomplete in $($file.FullName)"
    }
  }
}

if ($failed) {
  Write-Output "SpecBridge runtime summary validation failed."
  exit 1
}

Write-Output "SpecBridge runtime summary validation passed."
exit 0
