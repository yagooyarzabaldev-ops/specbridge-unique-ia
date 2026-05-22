param(
  [string] $RuntimeExecutionsPath = ".specbridge/runtime-executions"
)

$ErrorActionPreference = "Stop"

Write-Output "SpecBridge runtime execution validation started."

$failed = $false

$requiredFields = @(
  "schema_version",
  "execution_id",
  "generated_by",
  "runtime_launch_path",
  "launch_id",
  "task_id",
  "packet_id",
  "slice_id",
  "branch_name",
  "dry_run",
  "timeout_seconds",
  "allowed_tools",
  "permission_mode",
  "max_budget_usd",
  "command_summary",
  "prompt_sections",
  "execution_status",
  "exit_code",
  "timed_out",
  "stdout",
  "stderr",
  "policy_result",
  "execution_policy",
  "source_files"
)

$allowedFields = $requiredFields
$allowedExecutionStatuses = @("dry_run", "succeeded", "failed", "timed_out")
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

  if ($MustExist -and -not (Test-Path -LiteralPath $normalizedPath -PathType Leaf)) {
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

function Test-BooleanPolicy {
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
  }
}

function Test-StreamEvidence {
  param(
    [object] $Stream,
    [string] $FieldName,
    [string] $FileName
  )

  if ($null -eq $Stream -or $Stream.GetType().Name -notmatch "Object") {
    Write-Failure "$FieldName must be an object in $FileName"
    return
  }

  foreach ($required in @("captured", "length", "line_count", "sha256")) {
    if (-not $Stream.PSObject.Properties.Name.Contains($required)) {
      Write-Failure "$FieldName missing $required in $FileName"
    }
  }

  if ($Stream.PSObject.Properties.Name.Contains("captured") -and $Stream.captured -isnot [bool]) {
    Write-Failure "$FieldName.captured must be boolean in $FileName"
  }

  foreach ($integerField in @("length", "line_count")) {
    if ($Stream.PSObject.Properties.Name.Contains($integerField)) {
      $value = $Stream.$integerField

      if ($value -isnot [int] -and $value -isnot [long]) {
        Write-Failure "$FieldName.$integerField must be an integer in $FileName"
      }
      elseif ($value -lt 0) {
        Write-Failure "$FieldName.$integerField must not be negative in $FileName"
      }
    }
  }

  if ($Stream.PSObject.Properties.Name.Contains("sha256") -and $null -ne $Stream.sha256 -and $Stream.sha256 -notmatch "^[a-f0-9]{64}$") {
    Write-Failure "$FieldName.sha256 must be null or a lowercase SHA-256 hex digest in $FileName"
  }
}

if (-not (Test-Path -LiteralPath $RuntimeExecutionsPath -PathType Container)) {
  Write-Output "FAIL missing runtime executions directory: $RuntimeExecutionsPath"
  exit 1
}

$executionFiles = Get-ChildItem -LiteralPath $RuntimeExecutionsPath -Filter "*.runtime-execution.json" -File

if ($executionFiles.Count -le 0) {
  Write-Output "FAIL no runtime execution files found in $RuntimeExecutionsPath"
  exit 1
}

foreach ($file in $executionFiles) {
  Write-Output "Validating runtime execution: $($file.FullName)"

  try {
    $execution = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
  }
  catch {
    Write-Failure "runtime execution must contain valid JSON: $($file.FullName)"
    continue
  }

  $propertyNames = @($execution.PSObject.Properties.Name)

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

  if ($execution.schema_version -ne "1") {
    Write-Failure "schema_version must be 1 in $($file.FullName)"
  }

  foreach ($stringField in @("execution_id", "generated_by", "launch_id", "task_id", "packet_id", "slice_id", "branch_name", "permission_mode", "max_budget_usd", "command_summary", "execution_status", "policy_result")) {
    if ($propertyNames -contains $stringField) {
      $value = $execution.$stringField

      if ($null -eq $value -or $value.GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($value)) {
        Write-Failure "$stringField must be a non-empty string in $($file.FullName)"
      }
    }
  }

  if ($propertyNames -contains "runtime_launch_path") {
    Test-RepoPath -Path $execution.runtime_launch_path -FieldName "runtime_launch_path" -FileName $file.FullName -MustExist $true

    if ($execution.runtime_launch_path -notmatch "^\.specbridge/runtime-launches/.+\.runtime-launch\.json$") {
      Write-Failure "runtime_launch_path must point to a runtime launch in $($file.FullName)"
    }
  }

  if ($propertyNames -contains "dry_run" -and $execution.dry_run -isnot [bool]) {
    Write-Failure "dry_run must be boolean in $($file.FullName)"
  }

  if ($propertyNames -contains "timed_out" -and $execution.timed_out -isnot [bool]) {
    Write-Failure "timed_out must be boolean in $($file.FullName)"
  }

  if ($propertyNames -contains "timeout_seconds") {
    if ($execution.timeout_seconds -isnot [int] -and $execution.timeout_seconds -isnot [long]) {
      Write-Failure "timeout_seconds must be an integer in $($file.FullName)"
    }
    elseif ($execution.timeout_seconds -lt 30 -or $execution.timeout_seconds -gt 3600) {
      Write-Failure "timeout_seconds must be between 30 and 3600 in $($file.FullName)"
    }
  }

  if ($propertyNames -contains "exit_code" -and $null -ne $execution.exit_code) {
    if ($execution.exit_code -isnot [int] -and $execution.exit_code -isnot [long]) {
      Write-Failure "exit_code must be null or an integer in $($file.FullName)"
    }
    elseif ($execution.exit_code -lt 0 -or $execution.exit_code -gt 255) {
      Write-Failure "exit_code must be between 0 and 255 in $($file.FullName)"
    }
  }

  if ($propertyNames -contains "execution_status" -and $allowedExecutionStatuses -notcontains $execution.execution_status) {
    Write-Failure "execution_status is not allowed in $($file.FullName): $($execution.execution_status)"
  }

  $tools = @()

  if ($propertyNames -contains "allowed_tools") {
    $tools = Test-StringArray -Value $execution.allowed_tools -FieldName "allowed_tools" -FileName $file.FullName

    foreach ($tool in $tools) {
      if ($allowedTools -notcontains $tool) {
        Write-Failure "allowed_tools contains an unapproved tool in $($file.FullName): $tool"
      }
    }
  }

  if ($tools -notcontains "Read" -or $tools -notcontains "Write") {
    Write-Failure "allowed_tools must include Read and Write in $($file.FullName)"
  }

  [void] (Test-StringArray -Value $execution.prompt_sections -FieldName "prompt_sections" -FileName $file.FullName)

  $sourceFiles = @()

  if ($propertyNames -contains "source_files") {
    $sourceFiles = Test-StringArray -Value $execution.source_files -FieldName "source_files" -FileName $file.FullName

    foreach ($path in $sourceFiles) {
      Test-RepoPath -Path $path -FieldName "source_files" -FileName $file.FullName -MustExist $true
    }
  }

  if ($sourceFiles -notcontains $execution.runtime_launch_path) {
    Write-Failure "source_files must include runtime_launch_path in $($file.FullName)"
  }

  Test-StreamEvidence -Stream $execution.stdout -FieldName "stdout" -FileName $file.FullName
  Test-StreamEvidence -Stream $execution.stderr -FieldName "stderr" -FileName $file.FullName

  if ($propertyNames -contains "execution_policy") {
    if ($null -eq $execution.execution_policy -or $execution.execution_policy.GetType().Name -notmatch "Object") {
      Write-Failure "execution_policy must be an object in $($file.FullName)"
    }
    else {
      foreach ($policyField in @("launches_claude", "launches_antigravity", "executes_shell", "requires_network", "touches_secrets", "touches_production", "installs_dependencies", "deploys")) {
        Test-BooleanPolicy -Policy $execution.execution_policy -FieldName $policyField -FileName $file.FullName
      }

      foreach ($alwaysFalse in @("launches_antigravity", "executes_shell", "touches_secrets", "touches_production", "installs_dependencies", "deploys")) {
        if ($execution.execution_policy.PSObject.Properties.Name.Contains($alwaysFalse) -and $execution.execution_policy.$alwaysFalse -ne $false) {
          Write-Failure "execution_policy.$alwaysFalse must be false in $($file.FullName)"
        }
      }

      if ($execution.dry_run -eq $true) {
        foreach ($dryRunFalse in @("launches_claude", "requires_network")) {
          if ($execution.execution_policy.PSObject.Properties.Name.Contains($dryRunFalse) -and $execution.execution_policy.$dryRunFalse -ne $false) {
            Write-Failure "dry-run execution_policy.$dryRunFalse must be false in $($file.FullName)"
          }
        }
      }
    }
  }

  if ($propertyNames -contains "runtime_launch_path" -and (Test-Path -LiteralPath $execution.runtime_launch_path -PathType Leaf)) {
    try {
      $launch = Get-Content -LiteralPath $execution.runtime_launch_path -Raw | ConvertFrom-Json
    }
    catch {
      Write-Failure "source runtime launch must contain valid JSON in $($file.FullName)"
      continue
    }

    foreach ($matchingField in @("launch_id", "task_id", "packet_id", "slice_id", "branch_name", "permission_mode", "max_budget_usd")) {
      if ($launch.PSObject.Properties.Name.Contains($matchingField) -and $execution.PSObject.Properties.Name.Contains($matchingField) -and $execution.$matchingField -ne $launch.$matchingField) {
        Write-Failure "$matchingField must match source runtime launch in $($file.FullName)"
      }
    }
  }
}

if ($failed) {
  Write-Output "SpecBridge runtime execution validation failed."
  exit 1
}

Write-Output "SpecBridge runtime execution validation passed."
exit 0
