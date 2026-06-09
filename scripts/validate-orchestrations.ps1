$ErrorActionPreference = "Stop"

Write-Output "SpecBridge orchestration validation started."

$orchPath = ".specbridge/orchestrations"
$failed = $false

$allowedOrchStatuses  = @("planned", "in_progress", "completed", "cancelled")
$allowedAgentStatuses = @("pending", "active", "completed", "skipped", "failed")
$allowedAgentNames    = @("planner", "implementer", "reviewer", "tester", "security", "docs", "closure")

function Write-Failure {
  param([string] $Message)
  [Console]::Out.WriteLine("FAIL $Message")
  $script:failed = $true
}

if (-not (Test-Path $orchPath)) {
  Write-Output "No orchestrations directory found — skipping (no orchestrations exist yet)."
  exit 0
}

$orchFiles = @(Get-ChildItem $orchPath -Filter "*.orchestration.json" -File -ErrorAction SilentlyContinue)

if ($orchFiles.Count -eq 0) {
  Write-Output "No orchestration files found — skipping."
  exit 0
}

foreach ($file in $orchFiles) {
  Write-Output "Validating orchestration: $($file.FullName)"

  $raw = Get-Content $file.FullName -Raw -Encoding UTF8

  if ([string]::IsNullOrWhiteSpace($raw)) {
    Write-Failure "empty orchestration file: $($file.FullName)"
    continue
  }

  $orch = $null
  try { $orch = $raw | ConvertFrom-Json }
  catch {
    Write-Failure "invalid JSON in orchestration file: $($file.FullName)"
    continue
  }

  $props = @($orch.PSObject.Properties.Name)
  foreach ($req in @("schema_version", "task_id", "run_id", "coordinator", "created_at", "status", "agents")) {
    if ($props -notcontains $req) {
      Write-Failure "missing required field '$req' in $($file.FullName)"
    }
  }

  if ($orch.run_id -and $orch.run_id -notmatch "^sb-\d{8}-[a-f0-9]{8}$") {
    Write-Failure "invalid run_id format in $($file.FullName): $($orch.run_id)"
  }

  if ($orch.status -and $allowedOrchStatuses -notcontains $orch.status) {
    Write-Failure "invalid orchestration status '$($orch.status)' in $($file.FullName)"
  }

  if ($null -ne $orch.agents) {
    $agentNames = @()
    foreach ($ag in $orch.agents) {
      if ($null -eq $ag) { continue }
      $agProps = @($ag.PSObject.Properties.Name)
      foreach ($req in @("name", "role", "status")) {
        if ($agProps -notcontains $req) {
          Write-Failure "agent missing required field '$req' in $($file.FullName)"
        }
      }
      if ($ag.name -and $allowedAgentNames -notcontains $ag.name) {
        Write-Failure "unknown agent name '$($ag.name)' in $($file.FullName)"
      }
      if ($ag.status -and $allowedAgentStatuses -notcontains $ag.status) {
        Write-Failure "invalid agent status '$($ag.status)' for agent '$($ag.name)' in $($file.FullName)"
      }
      if ($ag.name) { $agentNames += $ag.name }
    }
    $dupes = $agentNames | Group-Object | Where-Object { $_.Count -gt 1 }
    foreach ($d in $dupes) {
      Write-Failure "duplicate agent name '$($d.Name)' in $($file.FullName)"
    }
  }
}

if ($failed) {
  Write-Output "SpecBridge orchestration validation failed."
  exit 1
}

Write-Output "SpecBridge orchestration validation passed."
exit 0
