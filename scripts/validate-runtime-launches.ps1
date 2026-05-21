param(
  [string] $RuntimeLaunchesPath = ".specbridge/runtime-launches"
)

$ErrorActionPreference = "Stop"

Write-Output "SpecBridge runtime launch validation started."

$failed = $false

$requiredFields = @(
  "schema_version",
  "launch_id",
  "generated_by",
  "source_executor_packet_path",
  "task_id",
  "packet_id",
  "slice_id",
  "agent_role",
  "goal",
  "branch_name",
  "execution_contract_path",
  "final_report_path",
  "exclusive_write",
  "read_only",
  "required_validations",
  "allowed_tools",
  "permission_mode",
  "max_budget_usd",
  "command_summary",
  "prompt_sections",
  "stop_conditions",
  "launch_status",
  "execution_policy",
  "source_files"
)

$allowedFields = $requiredFields
$allowedTools = @("Read", "Write", "Edit")
$allowedPermissionModes = @("acceptEdits", "auto", "default", "dontAsk", "plan")

function Write-Failure {
  param(
    [string] $Message
  )

  Write-Output "FAIL $Message"
  $script:failed = $true
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

  $normalizedPath = $Path.Replace("\", "/")

  if ([System.IO.Path]::IsPathRooted($normalizedPath)) {
    Write-Failure "$FieldName must be repository-relative in $FileName`: $Path"
  }

  if ($normalizedPath -match "(^|/)\.\.(/|$)") {
    Write-Failure "$FieldName must not traverse parent directories in $FileName`: $Path"
  }

  if ($MustExist -and -not (Test-Path $normalizedPath)) {
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
    Write-Failure "execution_policy.$FieldName must be false in planning-only runtime launches: $FileName"
  }
}

if (-not (Test-Path $RuntimeLaunchesPath)) {
  Write-Output "FAIL missing runtime launches directory: $RuntimeLaunchesPath"
  exit 1
}

$launchFiles = Get-ChildItem $RuntimeLaunchesPath -Filter "*.runtime-launch.json" -File

if ($launchFiles.Count -le 0) {
  Write-Output "FAIL no runtime launch files found in $RuntimeLaunchesPath"
  exit 1
}

foreach ($file in $launchFiles) {
  Write-Output "Validating runtime launch: $($file.FullName)"

  try {
    $launch = Get-Content $file.FullName -Raw | ConvertFrom-Json
  }
  catch {
    Write-Failure "invalid JSON in runtime launch: $($file.FullName)"
    continue
  }

  $propertyNames = @($launch.PSObject.Properties.Name)

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

  if ($launch.schema_version -ne "1") {
    Write-Failure "schema_version must be 1 in $($file.FullName)"
  }

  foreach ($stringField in @("launch_id", "generated_by", "task_id", "packet_id", "slice_id", "agent_role", "goal", "branch_name", "permission_mode", "max_budget_usd", "command_summary", "launch_status")) {
    if ($propertyNames -contains $stringField) {
      $value = $launch.$stringField

      if ($null -eq $value -or $value.GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($value)) {
        Write-Failure "$stringField must be a non-empty string in $($file.FullName)"
      }
    }
  }

  if ($propertyNames -contains "launch_status" -and $launch.launch_status -ne "ready_for_operator_launch") {
    Write-Failure "launch_status must be ready_for_operator_launch in $($file.FullName)"
  }

  if ($propertyNames -contains "permission_mode" -and $allowedPermissionModes -notcontains $launch.permission_mode) {
    Write-Failure "permission_mode is not allowed in $($file.FullName): $($launch.permission_mode)"
  }

  if ($propertyNames -contains "max_budget_usd") {
    if ($launch.max_budget_usd -notmatch "^[0-9]+(\.[0-9]{1,2})?$") {
      Write-Failure "max_budget_usd must be a decimal string in $($file.FullName)"
    }
    else {
      $budget = [decimal]::Parse($launch.max_budget_usd, [System.Globalization.CultureInfo]::InvariantCulture)

      if ($budget -le 0 -or $budget -gt 10) {
        Write-Failure "max_budget_usd must be greater than 0 and no more than 10 in $($file.FullName)"
      }
    }
  }

  if ($propertyNames -contains "source_executor_packet_path") {
    Test-RepoPath -Path $launch.source_executor_packet_path -FieldName "source_executor_packet_path" -FileName $file.FullName -MustExist $true

    if ($launch.source_executor_packet_path -notmatch "^\.specbridge/executor-packets/.+\.executor-packet\.json$") {
      Write-Failure "source_executor_packet_path must point to an executor packet in $($file.FullName): $($launch.source_executor_packet_path)"
    }
  }

  if ($propertyNames -contains "execution_contract_path") {
    Test-RepoPath -Path $launch.execution_contract_path -FieldName "execution_contract_path" -FileName $file.FullName -MustExist $true

    if ($launch.execution_contract_path -notmatch "^\.specbridge/contracts/.+\.execution\.md$") {
      Write-Failure "execution_contract_path must point to a contract in $($file.FullName): $($launch.execution_contract_path)"
    }
  }

  if ($propertyNames -contains "final_report_path") {
    Test-RepoPath -Path $launch.final_report_path -FieldName "final_report_path" -FileName $file.FullName

    if ($launch.final_report_path -notmatch "^\.specbridge/reports/.+\.final-report\.json$") {
      Write-Failure "final_report_path must point to a final report in $($file.FullName): $($launch.final_report_path)"
    }
  }

  foreach ($pathField in @("exclusive_write", "read_only", "source_files")) {
    if ($propertyNames -contains $pathField) {
      foreach ($path in (Test-StringArray -Value $launch.$pathField -FieldName $pathField -FileName $file.FullName)) {
        Test-RepoPath -Path $path -FieldName $pathField -FileName $file.FullName
      }
    }
  }

  [void] (Test-StringArray -Value $launch.required_validations -FieldName "required_validations" -FileName $file.FullName)
  [void] (Test-StringArray -Value $launch.prompt_sections -FieldName "prompt_sections" -FileName $file.FullName)
  [void] (Test-StringArray -Value $launch.stop_conditions -FieldName "stop_conditions" -FileName $file.FullName)

  $tools = Test-StringArray -Value $launch.allowed_tools -FieldName "allowed_tools" -FileName $file.FullName

  foreach ($tool in $tools) {
    if ($allowedTools -notcontains $tool) {
      Write-Failure "allowed_tools contains an unapproved tool in $($file.FullName): $tool"
    }
  }

  foreach ($requiredTool in @("Read", "Write")) {
    if ($tools -notcontains $requiredTool) {
      Write-Failure "allowed_tools must include $requiredTool in $($file.FullName)"
    }
  }

  if ($propertyNames -contains "command_summary") {
    if ($launch.command_summary -notmatch "claude -p") {
      Write-Failure "command_summary must describe non-interactive Claude print mode in $($file.FullName)"
    }

    if ($launch.command_summary -match "dangerously|bypassPermissions|sudo|curl\s+\S+\s*\|\s*bash") {
      Write-Failure "command_summary contains blocked runtime wording in $($file.FullName)"
    }
  }

  if ($propertyNames -contains "execution_policy") {
    if ($null -eq $launch.execution_policy -or $launch.execution_policy.GetType().Name -notmatch "Object") {
      Write-Failure "execution_policy must be an object in $($file.FullName)"
    }
    else {
      foreach ($policyField in @("launches_claude", "launches_antigravity", "executes_shell", "requires_network", "touches_secrets", "touches_production", "installs_dependencies", "deploys")) {
        Test-RequiredBooleanPolicy -Policy $launch.execution_policy -FieldName $policyField -FileName $file.FullName
      }
    }
  }

  $sourceFiles = @($launch.source_files)

  foreach ($requiredSourceFile in @($launch.source_executor_packet_path, $launch.execution_contract_path)) {
    if (-not [string]::IsNullOrWhiteSpace($requiredSourceFile) -and $sourceFiles -notcontains $requiredSourceFile) {
      Write-Failure "source_files must include referenced source path in $($file.FullName): $requiredSourceFile"
    }
  }
}

if ($failed) {
  Write-Output "SpecBridge runtime launch validation failed."
  exit 1
}

Write-Output "SpecBridge runtime launch validation passed."
exit 0
