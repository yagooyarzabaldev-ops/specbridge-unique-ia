param(
  [string] $RuntimePreflightsPath = ".specbridge/preflights"
)

$ErrorActionPreference = "Stop"

Write-Output "SpecBridge runtime preflight validation started."

$failed = $false

$requiredFields = @(
  "schema_version",
  "command",
  "ok",
  "mode",
  "input_paths",
  "loaded_launches",
  "required_slices",
  "present_slices",
  "missing_required_slices",
  "duplicate_slices",
  "non_overlap",
  "budget",
  "tools",
  "execution_policy",
  "blockers",
  "policy_boundary",
  "source_files",
  "output_path"
)

$allowedFields = $requiredFields
$allowedResults = @("pass", "fail")

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

function Test-ResultObject {
  param(
    [object] $Value,
    [string] $FieldName,
    [string] $FileName
  )

  if ($null -eq $Value -or $Value.GetType().Name -notmatch "Object") {
    Write-Failure "$FieldName must be an object in $FileName"
    return
  }

  if (-not $Value.PSObject.Properties.Name.Contains("result")) {
    Write-Failure "$FieldName missing result in $FileName"
    return
  }

  if ($allowedResults -notcontains $Value.result) {
    Write-Failure "$FieldName result must be pass or fail in $FileName`: $($Value.result)"
  }
}

if (-not (Test-Path $RuntimePreflightsPath)) {
  Write-Output "FAIL missing runtime preflights directory: $RuntimePreflightsPath"
  exit 1
}

$preflightFiles = Get-ChildItem $RuntimePreflightsPath -Filter "*.runtime-preflight.json" -File

if ($preflightFiles.Count -le 0) {
  Write-Output "FAIL no runtime preflight files found in $RuntimePreflightsPath"
  exit 1
}

foreach ($file in $preflightFiles) {
  Write-Output "Validating runtime preflight: $($file.FullName)"

  try {
    $preflight = Get-Content $file.FullName -Raw | ConvertFrom-Json
  }
  catch {
    Write-Failure "invalid JSON in runtime preflight: $($file.FullName)"
    continue
  }

  $propertyNames = @($preflight.PSObject.Properties.Name)

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

  if ($preflight.schema_version -ne "1") {
    Write-Failure "schema_version must be 1 in $($file.FullName)"
  }

  if ($preflight.command -ne "preflight-runtime-launches") {
    Write-Failure "command must be preflight-runtime-launches in $($file.FullName)"
  }

  if ($preflight.mode -ne "plan_only_preflight") {
    Write-Failure "mode must be plan_only_preflight in $($file.FullName)"
  }

  if ($preflight.ok -isnot [bool]) {
    Write-Failure "ok must be boolean in $($file.FullName)"
  }

  if ($preflight.ok -ne $true) {
    Write-Failure "committed runtime preflight artifacts must have ok=true in $($file.FullName)"
  }

  foreach ($path in (Test-StringArray -Value $preflight.input_paths -FieldName "input_paths" -FileName $file.FullName)) {
    Test-RepoPath -Path $path -FieldName "input_paths" -FileName $file.FullName -MustExist $true

    if ($path -notmatch "^\.specbridge/runtime-launches/.+\.runtime-launch\.json$") {
      Write-Failure "input_paths must point to runtime launch artifacts in $($file.FullName): $path"
    }
  }

  foreach ($path in (Test-StringArray -Value $preflight.source_files -FieldName "source_files" -FileName $file.FullName)) {
    Test-RepoPath -Path $path -FieldName "source_files" -FileName $file.FullName -MustExist $true
  }

  [void] (Test-StringArray -Value $preflight.required_slices -FieldName "required_slices" -FileName $file.FullName -AllowEmpty $true)
  [void] (Test-StringArray -Value $preflight.present_slices -FieldName "present_slices" -FileName $file.FullName)
  [void] (Test-StringArray -Value $preflight.missing_required_slices -FieldName "missing_required_slices" -FileName $file.FullName -AllowEmpty $true)
  [void] (Test-StringArray -Value $preflight.duplicate_slices -FieldName "duplicate_slices" -FileName $file.FullName -AllowEmpty $true)
  [void] (Test-StringArray -Value $preflight.blockers -FieldName "blockers" -FileName $file.FullName -AllowEmpty $true)

  if (@($preflight.missing_required_slices).Count -gt 0) {
    Write-Failure "committed runtime preflight must not have missing required slices in $($file.FullName)"
  }

  if (@($preflight.duplicate_slices).Count -gt 0) {
    Write-Failure "committed runtime preflight must not have duplicate slices in $($file.FullName)"
  }

  if (@($preflight.blockers).Count -gt 0) {
    Write-Failure "committed runtime preflight must not have blockers in $($file.FullName)"
  }

  if ($null -eq $preflight.loaded_launches -or -not ($preflight.loaded_launches -is [System.Array]) -or @($preflight.loaded_launches).Count -le 0) {
    Write-Failure "loaded_launches must be a non-empty array in $($file.FullName)"
  }
  else {
    foreach ($launch in @($preflight.loaded_launches)) {
      foreach ($fieldName in @("path", "launch_id", "task_id", "packet_id", "slice_id", "branch_name", "max_budget_usd", "allowed_tools", "exclusive_write")) {
        if (-not $launch.PSObject.Properties.Name.Contains($fieldName)) {
          Write-Failure "loaded_launches item missing $fieldName in $($file.FullName)"
        }
      }

      if ($launch.PSObject.Properties.Name.Contains("path")) {
        Test-RepoPath -Path $launch.path -FieldName "loaded_launches.path" -FileName $file.FullName -MustExist $true
      }

      if ($launch.PSObject.Properties.Name.Contains("allowed_tools")) {
        [void] (Test-StringArray -Value $launch.allowed_tools -FieldName "loaded_launches.allowed_tools" -FileName $file.FullName)
      }

      if ($launch.PSObject.Properties.Name.Contains("exclusive_write")) {
        foreach ($path in (Test-StringArray -Value $launch.exclusive_write -FieldName "loaded_launches.exclusive_write" -FileName $file.FullName)) {
          Test-RepoPath -Path $path -FieldName "loaded_launches.exclusive_write" -FileName $file.FullName
        }
      }
    }
  }

  foreach ($resultField in @("non_overlap", "budget", "tools", "execution_policy")) {
    if ($propertyNames -contains $resultField) {
      Test-ResultObject -Value $preflight.$resultField -FieldName $resultField -FileName $file.FullName

      if ($preflight.$resultField.result -ne "pass") {
        Write-Failure "$resultField must pass in committed runtime preflight: $($file.FullName)"
      }
    }
  }

  if ($propertyNames -contains "output_path") {
    Test-RepoPath -Path $preflight.output_path -FieldName "output_path" -FileName $file.FullName -MustExist $true

    if ($preflight.output_path -notmatch "^\.specbridge/preflights/.+\.runtime-preflight\.json$") {
      Write-Failure "output_path must point to a runtime preflight artifact in $($file.FullName): $($preflight.output_path)"
    }
  }
}

if ($failed) {
  Write-Output "SpecBridge runtime preflight validation failed."
  exit 1
}

Write-Output "SpecBridge runtime preflight validation passed."
exit 0
