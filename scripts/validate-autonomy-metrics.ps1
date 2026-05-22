param(
  [string] $MetricsPath = ".specbridge/metrics"
)

$ErrorActionPreference = "Stop"

Write-Output "SpecBridge autonomy metrics validation started."

$failed = $false

$requiredFields = @(
  "schema_version",
  "metrics_id",
  "generated_by",
  "task_filter",
  "summary_count",
  "ready_count",
  "blocked_count",
  "executor_count",
  "validation_totals",
  "runtime_status_counts",
  "result_status_counts",
  "completion_status_counts",
  "merge_readiness_counts",
  "policy_gate_ready_rate",
  "source_summaries",
  "source_results",
  "source_files"
)

$allowedFields = $requiredFields

function Write-Failure {
  param(
    [string] $Message
  )

  Write-Output "FAIL $Message"
  $script:failed = $true
}

function Test-IntegerField {
  param(
    [object] $Object,
    [string] $FieldName,
    [string] $FileName
  )

  if (-not $Object.PSObject.Properties.Name.Contains($FieldName)) {
    Write-Failure "missing integer field in $FileName`: $FieldName"
    return 0
  }

  $value = $Object.$FieldName

  if ($value -isnot [int] -and $value -isnot [long]) {
    Write-Failure "$FieldName must be an integer in $FileName"
    return 0
  }

  if ($value -lt 0) {
    Write-Failure "$FieldName must not be negative in $FileName"
  }

  return [int] $value
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

  $normalizedPath = $Path.Trim().Replace("\", "/")

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

if (-not (Test-Path $MetricsPath)) {
  Write-Output "FAIL missing autonomy metrics directory: $MetricsPath"
  exit 1
}

$metricFiles = Get-ChildItem $MetricsPath -Filter "*.autonomy-metrics.json" -File

if ($metricFiles.Count -le 0) {
  Write-Output "FAIL no autonomy metrics files found in $MetricsPath"
  exit 1
}

foreach ($file in $metricFiles) {
  Write-Output "Validating autonomy metrics: $($file.FullName)"

  try {
    $metrics = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
  }
  catch {
    Write-Failure "autonomy metrics must contain valid JSON: $($file.FullName)"
    continue
  }

  $propertyNames = @($metrics.PSObject.Properties.Name)

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

  if ($metrics.schema_version -ne "1") {
    Write-Failure "schema_version must be 1 in $($file.FullName)"
  }

  foreach ($stringField in @("metrics_id", "generated_by")) {
    if ($propertyNames -contains $stringField) {
      $value = $metrics.$stringField

      if ($null -eq $value -or $value.GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($value)) {
        Write-Failure "$stringField must be a non-empty string in $($file.FullName)"
      }
    }
  }

  if ($propertyNames -contains "task_filter" -and $null -ne $metrics.task_filter -and ($metrics.task_filter.GetType().Name -ne "String" -or [string]::IsNullOrWhiteSpace($metrics.task_filter))) {
    Write-Failure "task_filter must be null or a non-empty string in $($file.FullName)"
  }

  $summaryCount = Test-IntegerField -Object $metrics -FieldName "summary_count" -FileName $file.FullName
  $readyCount = Test-IntegerField -Object $metrics -FieldName "ready_count" -FileName $file.FullName
  $blockedCount = Test-IntegerField -Object $metrics -FieldName "blocked_count" -FileName $file.FullName
  [void] (Test-IntegerField -Object $metrics -FieldName "executor_count" -FileName $file.FullName)

  if ($summaryCount -le 0) {
    Write-Failure "summary_count must be greater than zero in $($file.FullName)"
  }

  if ($readyCount + $blockedCount -gt $summaryCount) {
    Write-Failure "ready_count plus blocked_count must not exceed summary_count in $($file.FullName)"
  }

  if ($propertyNames -contains "policy_gate_ready_rate") {
    if ($metrics.policy_gate_ready_rate -isnot [double] -and $metrics.policy_gate_ready_rate -isnot [decimal] -and $metrics.policy_gate_ready_rate -isnot [int] -and $metrics.policy_gate_ready_rate -isnot [long]) {
      Write-Failure "policy_gate_ready_rate must be numeric in $($file.FullName)"
    }
    elseif ($metrics.policy_gate_ready_rate -lt 0 -or $metrics.policy_gate_ready_rate -gt 1) {
      Write-Failure "policy_gate_ready_rate must be between 0 and 1 in $($file.FullName)"
    }
  }

  if ($propertyNames -contains "validation_totals") {
    if ($null -eq $metrics.validation_totals -or $metrics.validation_totals.GetType().Name -notmatch "Object") {
      Write-Failure "validation_totals must be an object in $($file.FullName)"
    }
    else {
      $total = Test-IntegerField -Object $metrics.validation_totals -FieldName "total" -FileName $file.FullName
      $passed = Test-IntegerField -Object $metrics.validation_totals -FieldName "passed" -FileName $file.FullName
      $failedCount = Test-IntegerField -Object $metrics.validation_totals -FieldName "failed" -FileName $file.FullName
      $other = Test-IntegerField -Object $metrics.validation_totals -FieldName "other" -FileName $file.FullName

      if ($total -ne ($passed + $failedCount + $other)) {
        Write-Failure "validation_totals.total must equal passed + failed + other in $($file.FullName)"
      }
    }
  }

  foreach ($objectField in @("runtime_status_counts", "result_status_counts", "completion_status_counts", "merge_readiness_counts")) {
    if ($propertyNames -contains $objectField -and ($null -eq $metrics.$objectField -or $metrics.$objectField.GetType().Name -notmatch "Object")) {
      Write-Failure "$objectField must be an object in $($file.FullName)"
    }
  }

  $sourceSummaries = @()

  if ($propertyNames -contains "source_summaries") {
    $sourceSummaries = Test-StringArray -Value $metrics.source_summaries -FieldName "source_summaries" -FileName $file.FullName

    foreach ($path in $sourceSummaries) {
      Test-RepoPath -Path $path -FieldName "source_summaries" -FileName $file.FullName -MustExist $true

      if ($path -notmatch "^\.specbridge/runtime-summaries/.+\.runtime-summary\.json$") {
        Write-Failure "source_summaries must point to runtime summaries in $($file.FullName): $path"
      }
    }
  }

  if ($sourceSummaries.Count -ne $summaryCount) {
    Write-Failure "source_summaries count must equal summary_count in $($file.FullName)"
  }

  if ($propertyNames -contains "source_results") {
    foreach ($path in (Test-StringArray -Value $metrics.source_results -FieldName "source_results" -FileName $file.FullName -AllowEmpty $true)) {
      Test-RepoPath -Path $path -FieldName "source_results" -FileName $file.FullName -MustExist $true

      if ($path -notmatch "^\.specbridge/runtime-results/.+\.runtime-result\.json$") {
        Write-Failure "source_results must point to runtime results in $($file.FullName): $path"
      }
    }
  }

  if ($propertyNames -contains "source_files") {
    foreach ($path in (Test-StringArray -Value $metrics.source_files -FieldName "source_files" -FileName $file.FullName)) {
      Test-RepoPath -Path $path -FieldName "source_files" -FileName $file.FullName -MustExist $true
    }
  }
}

if ($failed) {
  Write-Output "SpecBridge autonomy metrics validation failed."
  exit 1
}

Write-Output "SpecBridge autonomy metrics validation passed."
exit 0
