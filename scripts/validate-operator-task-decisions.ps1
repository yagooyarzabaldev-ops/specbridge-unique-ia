$ErrorActionPreference = "Stop"

Write-Output "SpecBridge operator task decision validation started."

$registryPath = ".specbridge/policies/operator-task-decisions.json"
$failed = $false

$allowedDecisions = @("not_planned", "deferred", "superseded", "blocked")

function Write-Failure {
  param([string] $Message)
  Write-Output "FAIL $Message"
  $script:failed = $true
}

if (-not (Test-Path -LiteralPath $registryPath -PathType Leaf)) {
  Write-Output "No operator task decision registry found - skipping (no decisions recorded yet)."
  exit 0
}

$raw = Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8

if ([string]::IsNullOrWhiteSpace($raw)) {
  Write-Failure "empty operator task decision registry: $registryPath"
}

$registry = $null
if (-not $failed) {
  try { $registry = $raw | ConvertFrom-Json }
  catch {
    Write-Failure "invalid JSON in operator task decision registry: $registryPath"
  }
}

if ($null -ne $registry) {
  $props = @($registry.PSObject.Properties.Name)
  foreach ($req in @("schema_version", "decisions")) {
    if ($props -notcontains $req) {
      Write-Failure "missing required field '$req' in $registryPath"
    }
  }

  $seenIssues = @{}
  foreach ($decision in @($registry.decisions)) {
    if ($null -eq $decision) { continue }
    $dProps = @($decision.PSObject.Properties.Name)
    foreach ($req in @("github_issue", "task_id", "decision", "reason", "decided_by", "decided_at")) {
      if ($dProps -notcontains $req) {
        Write-Failure "decision missing required field '$req' in $registryPath"
      }
    }

    if ($null -ne $decision.github_issue) {
      $issueNumber = 0
      if (-not [int]::TryParse([string]$decision.github_issue, [ref]$issueNumber) -or $issueNumber -le 0) {
        Write-Failure "github_issue must be a positive integer in $registryPath (got '$($decision.github_issue)')"
      } else {
        if ($seenIssues.ContainsKey($issueNumber)) {
          Write-Failure "duplicate decision for github_issue $issueNumber in $registryPath"
        }
        $seenIssues[$issueNumber] = $true
      }
    }

    if ($decision.decision -and $allowedDecisions -notcontains $decision.decision) {
      Write-Failure "invalid decision '$($decision.decision)' in $registryPath. Allowed: $($allowedDecisions -join ', ')"
    }

    if ($dProps -contains "task_id" -and [string]::IsNullOrWhiteSpace([string]$decision.task_id)) {
      Write-Failure "task_id must not be empty in $registryPath"
    }

    if ($dProps -contains "reason" -and [string]::IsNullOrWhiteSpace([string]$decision.reason)) {
      Write-Failure "reason is mandatory for every decision in $registryPath"
    }

    if ($dProps -contains "decided_by" -and [string]::IsNullOrWhiteSpace([string]$decision.decided_by)) {
      Write-Failure "decided_by must not be empty in $registryPath"
    }

    if ($decision.decided_at) {
      $parsedDate = [datetime]::MinValue
      if (-not [datetime]::TryParse([string]$decision.decided_at, [ref]$parsedDate)) {
        Write-Failure "decided_at is not a valid timestamp in $registryPath (got '$($decision.decided_at)')"
      }
    }
  }
}

if ($failed) {
  Write-Output "SpecBridge operator task decision validation failed."
  exit 1
}

Write-Output "SpecBridge operator task decision validation passed."
exit 0
