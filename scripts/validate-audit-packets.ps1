param(
  [string] $AuditPacketsPath = ".specbridge/audit-packets"
)

$ErrorActionPreference = "Stop"

Write-Output "SpecBridge audit packet validation started."

$failed = $false

$requiredFields = @(
  "schema_version",
  "task_id",
  "generated_by",
  "execution_contract_path",
  "changed_files",
  "diff_summary",
  "validation_commands",
  "validation_results",
  "final_report_path",
  "ci_status",
  "pr_review_report_path",
  "policy_result",
  "unresolved_risks",
  "completion_status",
  "source_files",
  "secret_omission"
)

$allowedFields = $requiredFields
$allowedCiStatuses = @("not_collected", "pending", "passed", "failed", "mixed", "unknown")

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
    [bool] $AllowNull = $false
  )

  if ($AllowNull -and $null -eq $Path) {
    return
  }

  if ($null -eq $Path -or $Path.GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($Path)) {
    Write-Failure "$FieldName must be a non-empty repository-relative path in $FileName"
    return
  }

  if ([System.IO.Path]::IsPathRooted($Path)) {
    Write-Failure "$FieldName must be repository-relative in $FileName`: $Path"
  }

  if ($Path -match "(^|/)\.\.(/|$)") {
    Write-Failure "$FieldName must not traverse parent directories in $FileName`: $Path"
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
      continue
    }
  }

  return @($items)
}

if (-not (Test-Path $AuditPacketsPath)) {
  Write-Output "FAIL missing audit packets directory: $AuditPacketsPath"
  exit 1
}

$packetFiles = Get-ChildItem $AuditPacketsPath -Filter "*.audit-packet.json" -File

if ($packetFiles.Count -le 0) {
  Write-Output "FAIL no audit packet files found in $AuditPacketsPath"
  exit 1
}

foreach ($file in $packetFiles) {
  Write-Output "Validating audit packet: $($file.FullName)"

  try {
    $packet = Get-Content $file.FullName -Raw | ConvertFrom-Json
  }
  catch {
    Write-Failure "invalid JSON in audit packet: $($file.FullName)"
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

  foreach ($stringField in @("task_id", "generated_by", "ci_status", "policy_result", "completion_status", "secret_omission")) {
    if ($propertyNames -contains $stringField) {
      $value = $packet.$stringField

      if ($null -eq $value -or $value.GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($value)) {
        Write-Failure "$stringField must be a non-empty string in $($file.FullName)"
      }
    }
  }

  if ($propertyNames -contains "ci_status" -and $allowedCiStatuses -notcontains $packet.ci_status) {
    Write-Failure "invalid ci_status in $($file.FullName): $($packet.ci_status)"
  }

  if ($propertyNames -contains "execution_contract_path") {
    Test-RepoPath -Path $packet.execution_contract_path -FieldName "execution_contract_path" -FileName $file.FullName

    if ($packet.execution_contract_path -notmatch "^\.specbridge/contracts/.+\.execution\.md$") {
      Write-Failure "execution_contract_path must point to a contract in $($file.FullName): $($packet.execution_contract_path)"
    }
  }

  if ($propertyNames -contains "final_report_path") {
    Test-RepoPath -Path $packet.final_report_path -FieldName "final_report_path" -FileName $file.FullName

    if ($packet.final_report_path -notmatch "^\.specbridge/reports/.+\.final-report\.json$") {
      Write-Failure "final_report_path must point to a final report in $($file.FullName): $($packet.final_report_path)"
    }
  }

  if ($propertyNames -contains "pr_review_report_path") {
    Test-RepoPath -Path $packet.pr_review_report_path -FieldName "pr_review_report_path" -FileName $file.FullName -AllowNull $true

    if ($null -ne $packet.pr_review_report_path -and $packet.pr_review_report_path -notmatch "^\.specbridge/review-reports/.+\.review-report\.json$") {
      Write-Failure "pr_review_report_path must point to a review report or null in $($file.FullName): $($packet.pr_review_report_path)"
    }
  }

  foreach ($path in (Test-StringArray -Value $packet.changed_files -FieldName "changed_files" -FileName $file.FullName)) {
    Test-RepoPath -Path $path -FieldName "changed_files" -FileName $file.FullName
  }

  foreach ($path in (Test-StringArray -Value $packet.source_files -FieldName "source_files" -FileName $file.FullName)) {
    Test-RepoPath -Path $path -FieldName "source_files" -FileName $file.FullName
  }

  [void] (Test-StringArray -Value $packet.validation_commands -FieldName "validation_commands" -FileName $file.FullName)
  [void] (Test-StringArray -Value $packet.unresolved_risks -FieldName "unresolved_risks" -FileName $file.FullName -AllowEmpty $true)

  if ($propertyNames -contains "diff_summary") {
    if ($null -eq $packet.diff_summary -or -not ($packet.diff_summary -is [System.Array]) -or @($packet.diff_summary).Count -le 0) {
      Write-Failure "diff_summary must be a non-empty array in $($file.FullName)"
    }

    foreach ($item in @($packet.diff_summary)) {
      foreach ($fieldName in @("file", "added_lines", "deleted_lines")) {
        if (-not $item.PSObject.Properties.Name.Contains($fieldName)) {
          Write-Failure "diff_summary item missing field in $($file.FullName): $fieldName"
        }
      }

      if ($item.PSObject.Properties.Name.Contains("file")) {
        Test-RepoPath -Path $item.file -FieldName "diff_summary.file" -FileName $file.FullName
      }

      foreach ($numericField in @("added_lines", "deleted_lines")) {
        if ($item.PSObject.Properties.Name.Contains($numericField) -and $null -ne $item.$numericField -and $item.$numericField -isnot [int]) {
          Write-Failure "diff_summary $numericField must be integer or null in $($file.FullName): file=$($item.file)"
        }
      }
    }
  }

  if ($propertyNames -contains "validation_results") {
    if ($null -eq $packet.validation_results -or -not ($packet.validation_results -is [System.Array]) -or @($packet.validation_results).Count -le 0) {
      Write-Failure "validation_results must be a non-empty array in $($file.FullName)"
    }

    foreach ($item in @($packet.validation_results)) {
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

  $rawPacket = Get-Content $file.FullName -Raw
  $forbiddenContentKeys = @(
    '"raw_diff"',
    '"file_contents"',
    '"secret"',
    '"token"',
    '"private_key"',
    '"credential"'
  )

  foreach ($key in $forbiddenContentKeys) {
    if ($rawPacket -match [regex]::Escape($key)) {
      Write-Failure "audit packet must not embed sensitive or raw content field in $($file.FullName): $key"
    }
  }
}

if ($failed) {
  Write-Output "SpecBridge audit packet validation failed."
  exit 1
}

Write-Output "SpecBridge audit packet validation passed."
exit 0
