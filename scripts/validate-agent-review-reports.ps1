$ErrorActionPreference = "Stop"

Write-Output "SpecBridge agent review report validation started."

$reviewPath = ".specbridge/agent-reviews"
$failed = $false

$allowedVerdicts   = @("approve", "block")
$allowedSeverities = @("info", "minor", "major", "blocker")

function Write-Failure {
  param([string] $Message)
  Write-Output "FAIL $Message"
  $script:failed = $true
}

if (-not (Test-Path $reviewPath)) {
  Write-Output "No agent-reviews directory found - skipping (no review reports exist yet)."
  exit 0
}

$reportFiles = @(Get-ChildItem $reviewPath -Filter "*.review-agent-report.json" -File -ErrorAction SilentlyContinue)

if ($reportFiles.Count -eq 0) {
  Write-Output "No review-agent reports found - skipping."
  exit 0
}

foreach ($file in $reportFiles) {
  Write-Output "Validating review-agent report: $($file.FullName)"

  $raw = Get-Content $file.FullName -Raw -Encoding UTF8

  if ([string]::IsNullOrWhiteSpace($raw)) {
    Write-Failure "empty review-agent report: $($file.FullName)"
    continue
  }

  $report = $null
  try { $report = $raw | ConvertFrom-Json }
  catch {
    Write-Failure "invalid JSON in review-agent report: $($file.FullName)"
    continue
  }

  $props = @($report.PSObject.Properties.Name)
  foreach ($req in @("schema_version", "task_id", "run_id", "reviewer", "verdict", "findings", "reviewed_commit", "created_at")) {
    if ($props -notcontains $req) {
      Write-Failure "missing required field '$req' in $($file.FullName)"
    }
  }

  if ($report.run_id -and $report.run_id -notmatch "^sb-\d{8}-[a-f0-9]{8}$") {
    Write-Failure "invalid run_id format in $($file.FullName): $($report.run_id)"
  }

  if ($report.verdict -and $allowedVerdicts -notcontains $report.verdict) {
    Write-Failure "invalid verdict '$($report.verdict)' in $($file.FullName)"
  }

  $blockerCount = 0
  if ($null -ne $report.findings) {
    foreach ($finding in @($report.findings)) {
      if ($null -eq $finding) { continue }
      $fProps = @($finding.PSObject.Properties.Name)
      foreach ($req in @("id", "severity", "summary")) {
        if ($fProps -notcontains $req) {
          Write-Failure "finding missing required field '$req' in $($file.FullName)"
        }
      }
      if ($finding.severity -and $allowedSeverities -notcontains $finding.severity) {
        Write-Failure "invalid finding severity '$($finding.severity)' in $($file.FullName)"
      }
      if ($finding.severity -eq "blocker") { $blockerCount++ }
    }
  }

  if ($blockerCount -gt 0 -and $report.verdict -eq "approve") {
    Write-Failure "verdict 'approve' is inconsistent with $blockerCount blocker finding(s) in $($file.FullName)"
  }

  # Filename must match the task_id inside the report
  $expectedName = "$($report.task_id).review-agent-report.json"
  if ($report.task_id -and $file.Name -ne $expectedName) {
    Write-Failure "report filename '$($file.Name)' does not match task_id '$($report.task_id)' in $($file.FullName)"
  }
}

if ($failed) {
  Write-Output "SpecBridge agent review report validation failed."
  exit 1
}

Write-Output "SpecBridge agent review report validation passed."
exit 0
