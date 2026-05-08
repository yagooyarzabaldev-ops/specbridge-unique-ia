$ErrorActionPreference = "Stop"

Write-Output "SpecBridge PR review report validation started."

$reportsPath = ".specbridge/review-reports"
$schemaPath = ".specbridge/schemas/claude-review-output.schema.json"
$failed = $false

if (-not (Test-Path $schemaPath)) {
  Write-Output "FAIL missing review report schema: $schemaPath"
  exit 1
}

if (-not (Test-Path $reportsPath)) {
  Write-Output "FAIL missing review reports directory: $reportsPath"
  exit 1
}

$reportFiles = Get-ChildItem $reportsPath -Filter "*.review-report.json" -File

if ($reportFiles.Count -le 0) {
  Write-Output "FAIL no PR review report files found in $reportsPath"
  exit 1
}

$allowedResults = @("pass", "fail", "needs_human_review")
$allowedSeverities = @("info", "low", "medium", "high", "critical")
$requiredTopLevelFields = @("schema_version", "reviewer", "summary", "findings", "result")
$requiredFindingFields = @("severity", "category", "file", "evidence", "recommendation", "blocking")

foreach ($file in $reportFiles) {
  Write-Output "Validating PR review report: $($file.FullName)"

  try {
    $json = Get-Content $file.FullName -Raw | ConvertFrom-Json
  } catch {
    Write-Output "FAIL invalid JSON in PR review report: $($file.FullName)"
    $failed = $true
    continue
  }

  foreach ($field in $requiredTopLevelFields) {
    if (-not $json.PSObject.Properties.Name.Contains($field)) {
      Write-Output "FAIL missing required field in $($file.FullName): $field"
      $failed = $true
    }
  }

  if ($json.schema_version -ne "1") {
    Write-Output "FAIL invalid schema_version in $($file.FullName): $($json.schema_version)"
    $failed = $true
  }

  if ([string]::IsNullOrWhiteSpace($json.reviewer)) {
    Write-Output "FAIL reviewer must not be empty in $($file.FullName)"
    $failed = $true
  }

  if ([string]::IsNullOrWhiteSpace($json.summary)) {
    Write-Output "FAIL summary must not be empty in $($file.FullName)"
    $failed = $true
  }

  if ($allowedResults -notcontains $json.result) {
    Write-Output "FAIL invalid result in $($file.FullName): $($json.result)"
    $failed = $true
  }

  if ($null -eq $json.findings) {
    Write-Output "FAIL findings must exist in $($file.FullName)"
    $failed = $true
    continue
  }

  $findings = @($json.findings)

  foreach ($finding in $findings) {
    foreach ($field in $requiredFindingFields) {
      if (-not $finding.PSObject.Properties.Name.Contains($field)) {
        Write-Output "FAIL missing finding field in $($file.FullName): $field"
        $failed = $true
      }
    }

    if ($finding.severity -and $allowedSeverities -notcontains $finding.severity) {
      Write-Output "FAIL invalid finding severity in $($file.FullName): $($finding.severity)"
      $failed = $true
    }

    if ([string]::IsNullOrWhiteSpace($finding.category)) {
      Write-Output "FAIL finding category must not be empty in $($file.FullName)"
      $failed = $true
    }

    if ([string]::IsNullOrWhiteSpace($finding.file)) {
      Write-Output "FAIL finding file must not be empty in $($file.FullName)"
      $failed = $true
    }

    if ([string]::IsNullOrWhiteSpace($finding.evidence)) {
      Write-Output "FAIL finding evidence must not be empty in $($file.FullName)"
      $failed = $true
    }

    if ([string]::IsNullOrWhiteSpace($finding.recommendation)) {
      Write-Output "FAIL finding recommendation must not be empty in $($file.FullName)"
      $failed = $true
    }

    if ($finding.blocking -isnot [bool]) {
      Write-Output "FAIL finding blocking must be boolean in $($file.FullName)"
      $failed = $true
    }
  }

  $blockingFindings = @($findings | Where-Object { $_.blocking -eq $true })

  if ($json.result -eq "pass" -and $blockingFindings.Count -gt 0) {
    Write-Output "FAIL result pass cannot contain blocking findings in $($file.FullName)"
    $failed = $true
  }

  if ($json.result -eq "fail" -and $blockingFindings.Count -eq 0) {
    Write-Output "FAIL result fail must contain at least one blocking finding in $($file.FullName)"
    $failed = $true
  }
}

if ($failed) {
  Write-Output "SpecBridge PR review report validation failed."
  exit 1
}

Write-Output "SpecBridge PR review report validation passed."
exit 0
