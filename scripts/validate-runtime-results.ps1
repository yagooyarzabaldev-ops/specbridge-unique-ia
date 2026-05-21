param(
  [string] $RuntimeResultsPath = ".specbridge/runtime-results"
)

$ErrorActionPreference = "Stop"

Write-Output "SpecBridge runtime result validation started."

$failed = $false

$requiredFields = @(
  "schema_version",
  "result_id",
  "generated_by",
  "source_runtime_launch_path",
  "launch_id",
  "task_id",
  "packet_id",
  "slice_id",
  "branch_name",
  "executor_evidence_path",
  "exit_code",
  "files_written",
  "validation_results",
  "policy_result",
  "stop_conditions",
  "completion_status",
  "runtime_status",
  "result_status",
  "execution_policy",
  "source_files"
)

$allowedFields = $requiredFields
$allowedCompletionStatuses = @("complete", "failed", "blocked", "partial", "needs_human_decision")
$allowedRuntimeStatuses = @("succeeded", "failed")

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
    [string] $FileName
  )

  if ($null -eq $Value -or -not ($Value -is [System.Array])) {
    Write-Failure "$FieldName must be an array in $FileName"
    return @()
  }

  $items = @($Value)

  if ($items.Count -le 0) {
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
    Write-Failure "execution_policy.$FieldName must be false in recording-only runtime results: $FileName"
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

if (-not (Test-Path $RuntimeResultsPath)) {
  Write-Output "FAIL missing runtime results directory: $RuntimeResultsPath"
  exit 1
}

$resultFiles = Get-ChildItem $RuntimeResultsPath -Filter "*.runtime-result.json" -File

if ($resultFiles.Count -le 0) {
  Write-Output "FAIL no runtime result files found in $RuntimeResultsPath"
  exit 1
}

foreach ($file in $resultFiles) {
  Write-Output "Validating runtime result: $($file.FullName)"

  $result = Read-JsonFile -Path $file.FullName -Description "runtime result"

  if ($null -eq $result) {
    continue
  }

  $propertyNames = @($result.PSObject.Properties.Name)

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

  if ($result.schema_version -ne "1") {
    Write-Failure "schema_version must be 1 in $($file.FullName)"
  }

  foreach ($stringField in @("result_id", "generated_by", "launch_id", "task_id", "packet_id", "slice_id", "branch_name", "policy_result", "completion_status", "runtime_status", "result_status")) {
    if ($propertyNames -contains $stringField) {
      $value = $result.$stringField

      if ($null -eq $value -or $value.GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($value)) {
        Write-Failure "$stringField must be a non-empty string in $($file.FullName)"
      }
    }
  }

  if ($propertyNames -contains "exit_code") {
    if ($result.exit_code -isnot [int] -and $result.exit_code -isnot [long]) {
      Write-Failure "exit_code must be an integer in $($file.FullName)"
    }
    elseif ($result.exit_code -lt 0 -or $result.exit_code -gt 255) {
      Write-Failure "exit_code must be between 0 and 255 in $($file.FullName)"
    }
  }

  if ($propertyNames -contains "completion_status" -and $allowedCompletionStatuses -notcontains $result.completion_status) {
    Write-Failure "completion_status is not allowed in $($file.FullName): $($result.completion_status)"
  }

  if ($propertyNames -contains "runtime_status" -and $allowedRuntimeStatuses -notcontains $result.runtime_status) {
    Write-Failure "runtime_status is not allowed in $($file.FullName): $($result.runtime_status)"
  }

  if ($propertyNames -contains "result_status" -and $result.result_status -ne "recorded") {
    Write-Failure "result_status must be recorded in $($file.FullName)"
  }

  if ($propertyNames -contains "source_runtime_launch_path") {
    Test-RepoPath -Path $result.source_runtime_launch_path -FieldName "source_runtime_launch_path" -FileName $file.FullName -MustExist $true

    if ($result.source_runtime_launch_path -notmatch "^\.specbridge/runtime-launches/.+\.runtime-launch\.json$") {
      Write-Failure "source_runtime_launch_path must point to a runtime launch in $($file.FullName): $($result.source_runtime_launch_path)"
    }
  }

  if ($propertyNames -contains "executor_evidence_path") {
    Test-RepoPath -Path $result.executor_evidence_path -FieldName "executor_evidence_path" -FileName $file.FullName -MustExist $true
  }

  $filesWritten = @()

  if ($propertyNames -contains "files_written") {
    $filesWritten = Test-StringArray -Value $result.files_written -FieldName "files_written" -FileName $file.FullName

    foreach ($path in $filesWritten) {
      Test-RepoPath -Path $path -FieldName "files_written" -FileName $file.FullName -MustExist $true
    }
  }

  if ($filesWritten -notcontains $result.executor_evidence_path) {
    Write-Failure "files_written must include executor_evidence_path in $($file.FullName): $($result.executor_evidence_path)"
  }

  [void] (Test-StringArray -Value $result.stop_conditions -FieldName "stop_conditions" -FileName $file.FullName)

  $sourceFiles = @()

  if ($propertyNames -contains "source_files") {
    $sourceFiles = Test-StringArray -Value $result.source_files -FieldName "source_files" -FileName $file.FullName

    foreach ($path in $sourceFiles) {
      Test-RepoPath -Path $path -FieldName "source_files" -FileName $file.FullName -MustExist $true
    }
  }

  foreach ($requiredSourceFile in @($result.source_runtime_launch_path, $result.executor_evidence_path)) {
    if (-not [string]::IsNullOrWhiteSpace($requiredSourceFile) -and $sourceFiles -notcontains $requiredSourceFile) {
      Write-Failure "source_files must include referenced source path in $($file.FullName): $requiredSourceFile"
    }
  }

  if ($propertyNames -contains "validation_results") {
    if ($null -eq $result.validation_results -or -not ($result.validation_results -is [System.Array]) -or @($result.validation_results).Count -le 0) {
      Write-Failure "validation_results must be a non-empty array in $($file.FullName)"
    }

    foreach ($item in @($result.validation_results)) {
      foreach ($fieldName in @("command", "result")) {
        if (-not $item.PSObject.Properties.Name.Contains($fieldName)) {
          Write-Failure "validation_results item missing field in $($file.FullName): $fieldName"
          continue
        }

        if ($null -eq $item.$fieldName -or $item.$fieldName.GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($item.$fieldName)) {
          Write-Failure "validation_results $fieldName must be a non-empty string in $($file.FullName)"
        }
      }
    }
  }

  if ($propertyNames -contains "execution_policy") {
    if ($null -eq $result.execution_policy -or $result.execution_policy.GetType().Name -notmatch "Object") {
      Write-Failure "execution_policy must be an object in $($file.FullName)"
    }
    else {
      foreach ($policyField in @("launches_claude", "launches_antigravity", "executes_shell", "requires_network", "touches_secrets", "touches_production", "installs_dependencies", "deploys")) {
        Test-RequiredBooleanPolicy -Policy $result.execution_policy -FieldName $policyField -FileName $file.FullName
      }
    }
  }

  if ($propertyNames -contains "source_runtime_launch_path" -and (Test-Path $result.source_runtime_launch_path -PathType Leaf)) {
    $launch = Read-JsonFile -Path $result.source_runtime_launch_path -Description "source runtime launch"

    if ($null -ne $launch) {
      foreach ($matchingField in @("launch_id", "task_id", "packet_id", "slice_id", "branch_name")) {
        if ($launch.PSObject.Properties.Name.Contains($matchingField) -and $result.PSObject.Properties.Name.Contains($matchingField) -and $result.$matchingField -ne $launch.$matchingField) {
          Write-Failure "$matchingField must match source runtime launch in $($file.FullName)"
        }
      }

      $exclusiveWrite = @($launch.exclusive_write | ForEach-Object { Normalize-RepoPath -Path $_ })

      if ($exclusiveWrite -notcontains $result.executor_evidence_path) {
        Write-Failure "executor_evidence_path must be declared in source runtime launch exclusive_write in $($file.FullName): $($result.executor_evidence_path)"
      }

      foreach ($path in $filesWritten) {
        if ($exclusiveWrite -notcontains $path) {
          Write-Failure "files_written path must be declared in source runtime launch exclusive_write in $($file.FullName): $path"
        }
      }
    }
  }
}

if ($failed) {
  Write-Output "SpecBridge runtime result validation failed."
  exit 1
}

Write-Output "SpecBridge runtime result validation passed."
exit 0
