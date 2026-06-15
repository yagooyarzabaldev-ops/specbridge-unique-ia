# Studio queue rendering helpers. Dot-sourced after dashboards.ps1.

function Get-StudioOperatorQueueHtml {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RepositoryRoot
  )

  $registryPath = Join-Path $RepositoryRoot ".specbridge/policies/operator-task-decisions.json"
  $decisions = @()
  if (Test-Path -LiteralPath $registryPath -PathType Leaf) {
    try {
      $registry = Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8 | ConvertFrom-Json
      if ($registry.decisions) { $decisions = @($registry.decisions) }
    } catch {}
  }

  $scopeDir = Join-Path $RepositoryRoot ".specbridge/scopes"
  $activeScopes = @()
  if (Test-Path $scopeDir) {
    foreach ($sf in (Get-ChildItem $scopeDir -Filter "*.scope.json" -ErrorAction SilentlyContinue)) {
      try {
        $scope = Get-Content -LiteralPath $sf.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($scope.status -eq "active") { $activeScopes += $scope }
      } catch {}
    }
  }

  $currentStatus = "unknown"
  $currentTask = "unknown"
  $cgPath = Join-Path $RepositoryRoot ".specbridge/state/current-goal.json"
  if (Test-Path -LiteralPath $cgPath -PathType Leaf) {
    try {
      $cg = Get-Content -LiteralPath $cgPath -Raw -Encoding UTF8 | ConvertFrom-Json
      if ($cg.status) { $currentStatus = $cg.status }
      if ($cg.current_task_id) { $currentTask = $cg.current_task_id }
    } catch {}
  }

  $excludedIds = @($decisions | ForEach-Object { $_.task_id })
  $eligible = @($activeScopes | Where-Object {
    $excludedIds -notcontains $_.contract_id -and -not ($currentStatus -eq "active" -and $_.contract_id -eq $currentTask)
  })

  $recommended = if ($currentStatus -eq "active") { "continue_current_goal" } elseif ($eligible.Count -gt 0) { "execute_eligible_task" } else { "create_new_operator_task" }
  $color = if ($recommended -eq "execute_eligible_task") { "#2d9e5f" } elseif ($recommended -eq "continue_current_goal") { "#7ab4f5" } else { "#e6a817" }

  $rows = ""
  foreach ($d in $decisions) {
    $issue = [System.Net.WebUtility]::HtmlEncode([string]$d.github_issue)
    $task = [System.Net.WebUtility]::HtmlEncode([string]$d.task_id)
    $reason = [System.Net.WebUtility]::HtmlEncode([string]$d.decision)
    $rows += "<tr><td>#$issue</td><td><code>$task</code></td><td style='color:#e6a817'>$reason</td></tr>"
  }
  $table = if ($rows) { "<table style='margin-top:8px'><tr><th>Issue</th><th>Task</th><th>Decision</th></tr>$rows</table>" } else { "<p style='color:#2d9e5f'>No excluded issues.</p>" }
  return "<p>Eligible tasks: <strong>$($eligible.Count)</strong> &nbsp; Excluded tasks: <strong>$($decisions.Count)</strong> &nbsp; Recommended action: <strong style='color:$color'>$recommended</strong></p>$table"
}
