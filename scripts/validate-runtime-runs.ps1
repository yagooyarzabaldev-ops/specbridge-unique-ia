param(
  [string] $RuntimeRunsPath = ".specbridge/runtime-runs"
)

$ErrorActionPreference = "Stop"

Write-Output "SpecBridge runtime run validation started."

$failed = $false

$requiredFields = @(
  "schema_version",
  "run_id",
  "generated_by",
  "runtime_launch_path",
  "launch_id",
  "task_id",
  "packet_id",
  "slice_id",
  "branch_name",
  "executor_evidence_path",
  "exit_code",
  "files_written",
  "validation_results",
  "tool_restriction",
  "permission_mode",
  "max_budget_usd",
  "policy_result",
  "stop_conditions",
  "completion_status",
  "runtime_status",
  "run_status",
  "runner_mode",
  "execution_policy",
  "source_files"
)

$allowedFields = $requiredFields
$allowedCompletionStatuses = @("complete", "failed", "blocked", "partial", "needs_human_decision")
$allowedRuntimeStatuses = @("succeeded", "failed")
$allowedRunnerModes = @("evidence_capture")
$allowedTools = @("Read", "Write", "Edit")

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
    Write-Failure "execution_policy.$FieldName must be false in evidence-capture runtime runs: $FileName"
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

if (-not (Test-Path $RuntimeRunsPath)) {
  Write-Output "FAIL missing runtime runs directory: $RuntimeRunsPath"
  exit 1
}

$runFiles = Get-ChildItem $RuntimeRunsPath -Filter "*.runtime-run.json" -File

if ($runFiles.Count -le 0) {
  Write-Output "FAIL no runtime run files found in $RuntimeRunsPath"
  exit 1
}

foreach ($file in $runFiles) {
  Write-Output "Validating runtime run: $($file.FullName)"

  $run = Read-JsonFile -Path $file.FullName -Description "runtime run"

  if ($null -eq $run) {
    continue
  }

  $propertyNames = @($run.PSObject.Properties.Name)

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

  if ($run.schema_version -ne "1") {
    Write-Failure "schema_version must be 1 in $($file.FullName)"
  }

  foreach ($stringField in @("run_id", "generated_by", "launch_id", "task_id", "packet_id", "slice_id", "branch_name", "permission_mode", "max_budget_usd", "policy_result", "completion_status", "runtime_status", "run_status", "runner_mode")) {
    if ($propertyNames -contains $stringField) {
      $value = $run.$stringField

      if ($null -eq $value -or $value.GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($value)) {
        Write-Failure "$stringField must be a non-empty string in $($file.FullName)"
      }
    }
  }

  if ($propertyNames -contains "exit_code") {
    if ($run.exit_code -isnot [int] -and $run.exit_code -isnot [long]) {
      Write-Failure "exit_code must be an integer in $($file.FullName)"
    }
    elseif ($run.exit_code -lt 0 -or $run.exit_code -gt 255) {
      Write-Failure "exit_code must be between 0 and 255 in $($file.FullName)"
    }
  }

  if ($propertyNames -contains "completion_status" -and $allowedCompletionStatuses -notcontains $run.completion_status) {
    Write-Failure "completion_status is not allowed in $($file.FullName): $($run.completion_status)"
  }

  if ($propertyNames -contains "runtime_status" -and $allowedRuntimeStatuses -notcontains $run.runtime_status) {
    Write-Failure "runtime_status is not allowed in $($file.FullName): $($run.runtime_status)"
  }

  if ($propertyNames -contains "run_status" -and $run.run_status -ne "recorded") {
    Write-Failure "run_status must be recorded in $($file.FullName)"
  }

  if ($propertyNames -contains "runner_mode" -and $allowedRunnerModes -notcontains $run.runner_mode) {
    Write-Failure "runner_mode is not allowed in $($file.FullName): $($run.runner_mode)"
  }

  if ($propertyNames -contains "runtime_launch_path") {
    Test-RepoPath -Path $run.runtime_launch_path -FieldName "runtime_launch_path" -FileName $file.FullName -MustExist $true

    if ($run.runtime_launch_path -notmatch "^\.specbridge/runtime-launches/.+\.runtime-launch\.json$") {
      Write-Failure "runtime_launch_path must point to a runtime launch in $($file.FullName): $($run.runtime_launch_path)"
    }
  }

  if ($propertyNames -contains "executor_evidence_path") {
    Test-RepoPath -Path $run.executor_evidence_path -FieldName "executor_evidence_path" -FileName $file.FullName -MustExist $true
  }

  $filesWritten = @()

  if ($propertyNames -contains "files_written") {
    $filesWritten = Test-StringArray -Value $run.files_written -FieldName "files_written" -FileName $file.FullName

    foreach ($path in $filesWritten) {
      Test-RepoPath -Path $path -FieldName "files_written" -FileName $file.FullName -MustExist $true
    }
  }

  if ($filesWritten -notcontains $run.executor_evidence_path) {
    Write-Failure "files_written must include executor_evidence_path in $($file.FullName): $($run.executor_evidence_path)"
  }

  [void] (Test-StringArray -Value $run.stop_conditions -FieldName "stop_conditions" -FileName $file.FullName)
  [void] (Test-StringArray -Value $run.tool_restriction -FieldName "tool_restriction" -FileName $file.FullName)

  foreach ($tool in @($run.tool_restriction)) {
    if ($allowedTools -notcontains $tool) {
      Write-Failure "tool_restriction contains an unapproved tool in $($file.FullName): $tool"
    }
  }

  $sourceFiles = @()

  if ($propertyNames -contains "source_files") {
    $sourceFiles = Test-StringArray -Value $run.source_files -FieldName "source_files" -FileName $file.FullName

    foreach ($path in $sourceFiles) {
      Test-RepoPath -Path $path -FieldName "source_files" -FileName $file.FullName -MustExist $true
    }
  }

  foreach ($requiredSourceFile in @($run.runtime_launch_path, $run.executor_evidence_path)) {
    if (-not [string]::IsNullOrWhiteSpace($requiredSourceFile) -and $sourceFiles -notcontains $requiredSourceFile) {
      Write-Failure "source_files must include referenced source path in $($file.FullName): $requiredSourceFile"
    }
  }

  if ($propertyNames -contains "validation_results") {
    if ($null -eq $run.validation_results -or -not ($run.validation_results -is [System.Array]) -or @($run.validation_results).Count -le 0) {
      Write-Failure "validation_results must be a non-empty array in $($file.FullName)"
    }

    foreach ($item in @($run.validation_results)) {
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
    if ($null -eq $run.execution_policy -or $run.execution_policy.GetType().Name -notmatch "Object") {
      Write-Failure "execution_policy must be an object in $($file.FullName)"
    }
    else {
      foreach ($policyField in @("launches_claude", "launches_antigravity", "executes_shell", "requires_network", "touches_secrets", "touches_production", "installs_dependencies", "deploys")) {
        Test-RequiredBooleanPolicy -Policy $run.execution_policy -FieldName $policyField -FileName $file.FullName
      }
    }
  }

  if ($propertyNames -contains "runtime_launch_path" -and (Test-Path $run.runtime_launch_path -PathType Leaf)) {
    $launch = Read-JsonFile -Path $run.runtime_launch_path -Description "source runtime launch"

    if ($null -ne $launch) {
      foreach ($matchingField in @("launch_id", "task_id", "packet_id", "slice_id", "branch_name", "permission_mode", "max_budget_usd")) {
        if ($launch.PSObject.Properties.Name.Contains($matchingField) -and $run.PSObject.Properties.Name.Contains($matchingField) -and $run.$matchingField -ne $launch.$matchingField) {
          Write-Failure "$matchingField must match source runtime launch in $($file.FullName)"
        }
      }

      $exclusiveWrite = @($launch.exclusive_write | ForEach-Object { Normalize-RepoPath -Path $_ })

      if ($exclusiveWrite -notcontains $run.executor_evidence_path) {
        Write-Failure "executor_evidence_path must be declared in source runtime launch exclusive_write in $($file.FullName): $($run.executor_evidence_path)"
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
  Write-Output "SpecBridge runtime run validation failed."
  exit 1
}

Write-Output "SpecBridge runtime run validation passed."
exit 0
