param(
  [string] $PacketsPath = ".specbridge/executor-packets"
)

$ErrorActionPreference = "Stop"

Write-Output "SpecBridge executor packet validation started."

$failed = $false

$requiredFields = @(
  "schema_version",
  "packet_id",
  "task_id",
  "slice_id",
  "agent_role",
  "goal",
  "launch_mode",
  "branch_name",
  "execution_contract_path",
  "final_report_path",
  "exclusive_write",
  "read_only",
  "required_validations",
  "stop_conditions",
  "status",
  "source_files",
  "generated_by"
)

$allowedFields = $requiredFields
$allowedLaunchModes = @("manual_antigravity")
$allowedStatuses = @("ready_for_handoff", "claimed", "in_progress", "blocked", "completed", "cancelled")

function Write-Failure {
  param(
    [string] $Message
  )

  Write-Output "FAIL $Message"
  $script:failed = $true
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
    return $null
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

  return $normalized
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

if (-not (Test-Path -LiteralPath $PacketsPath)) {
  Write-Output "FAIL missing executor packet directory: $PacketsPath"
  exit 1
}

$packetFiles = Get-ChildItem -LiteralPath $PacketsPath -Filter "*.executor-packet.json" -File

if ($packetFiles.Count -le 0) {
  Write-Output "FAIL no executor packet files found in $PacketsPath"
  exit 1
}

$packetIds = @{}
$branchNames = @{}

foreach ($file in $packetFiles) {
  Write-Output "Validating executor packet: $($file.FullName)"

  try {
    $packet = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
  }
  catch {
    Write-Failure "invalid JSON in executor packet: $($file.FullName)"
    continue
  }

  $propertyNames = @($packet.PSObject.Properties.Name)

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

  if ($packet.schema_version -ne "1") {
    Write-Failure "schema_version must be 1 in $($file.FullName)"
  }

  foreach ($stringField in @("packet_id", "task_id", "slice_id", "agent_role", "goal", "launch_mode", "branch_name", "status", "generated_by")) {
    if ($propertyNames -contains $stringField) {
      $value = $packet.$stringField

      if ($null -eq $value -or $value.GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($value)) {
        Write-Failure "$stringField must be a non-empty string in $($file.FullName)"
      }
    }
  }

  if ($allowedLaunchModes -notcontains $packet.launch_mode) {
    Write-Failure "invalid launch_mode in $($file.FullName): $($packet.launch_mode)"
  }

  if ($allowedStatuses -notcontains $packet.status) {
    Write-Failure "invalid status in $($file.FullName): $($packet.status)"
  }

  if ($packet.branch_name -notmatch "^[A-Za-z0-9._/-]+$" -or $packet.branch_name -match "(^|/)\.\.(/|$)") {
    Write-Failure "branch_name contains unsupported characters in $($file.FullName): $($packet.branch_name)"
  }

  if ($packetIds.ContainsKey($packet.packet_id)) {
    Write-Failure "duplicate packet_id across executor packets: $($packet.packet_id)"
  }
  else {
    $packetIds[$packet.packet_id] = $file.FullName
  }

  if ($branchNames.ContainsKey($packet.branch_name)) {
    Write-Failure "duplicate branch_name across executor packets: $($packet.branch_name)"
  }
  else {
    $branchNames[$packet.branch_name] = $file.FullName
  }

  $contractPath = Test-RepoPath -Path $packet.execution_contract_path -FieldName "execution_contract_path" -FileName $file.FullName -MustExist $true

  if ($contractPath -and $contractPath -notmatch "^\.specbridge/contracts/.+\.execution\.md$") {
    Write-Failure "execution_contract_path must point to a SpecBridge contract in $($file.FullName): $contractPath"
  }

  $finalReportPath = Test-RepoPath -Path $packet.final_report_path -FieldName "final_report_path" -FileName $file.FullName

  if ($finalReportPath -and $finalReportPath -notmatch "^\.specbridge/reports/.+\.final-report\.json$") {
    Write-Failure "final_report_path must point to a SpecBridge final report path in $($file.FullName): $finalReportPath"
  }

  foreach ($path in (Test-StringArray -Value $packet.exclusive_write -FieldName "exclusive_write" -FileName $file.FullName)) {
    [void] (Test-RepoPath -Path $path -FieldName "exclusive_write" -FileName $file.FullName)
  }

  foreach ($path in (Test-StringArray -Value $packet.read_only -FieldName "read_only" -FileName $file.FullName -AllowEmpty $true)) {
    [void] (Test-RepoPath -Path $path -FieldName "read_only" -FileName $file.FullName)
  }

  [void] (Test-StringArray -Value $packet.required_validations -FieldName "required_validations" -FileName $file.FullName)
  [void] (Test-StringArray -Value $packet.stop_conditions -FieldName "stop_conditions" -FileName $file.FullName)

  foreach ($path in (Test-StringArray -Value $packet.source_files -FieldName "source_files" -FileName $file.FullName)) {
    [void] (Test-RepoPath -Path $path -FieldName "source_files" -FileName $file.FullName -MustExist $true)
  }
}

if ($failed) {
  Write-Output "SpecBridge executor packet validation failed."
  exit 1
}

Write-Output "SpecBridge executor packet validation passed."
exit 0
