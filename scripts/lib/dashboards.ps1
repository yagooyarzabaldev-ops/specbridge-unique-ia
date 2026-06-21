# SpecBridge CLI library: dashboards
# Dot-sourced by scripts/specbridge.ps1. Do not run directly.

function Write-DashboardHtmlFile {
  param(
    [string] $Path,
    [string] $Value
  )

  $normalized = (($Value -split "\r?\n") | ForEach-Object { $_.TrimEnd() }) -join "`n"
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, ($normalized + "`n"), $utf8NoBom)
}

function Invoke-GenerateDashboardCommand {
  $repoSlug = ($RepositoryUrl -replace "https://github\.com/", "")

  # Gather data from artifacts
  $scopes = [System.Collections.Generic.List[object]]::new()
  $scopeDir = Join-Path $repoRoot ".specbridge/scopes"
  if (Test-Path $scopeDir) {
    foreach ($sf in (Get-ChildItem $scopeDir -Filter "*.scope.json")) {
      try { $scopes.Add((Get-Content $sf.FullName -Raw -Encoding UTF8 | ConvertFrom-Json)) } catch {}
    }
  }
  $completedScopes = @($scopes | Where-Object { $_.status -eq "completed" })
  $activeScopes    = @($scopes | Where-Object { $_.status -eq "active" })

  $ledgerEntries = [System.Collections.Generic.List[object]]::new()
  $ledgerPath = Join-Path $repoRoot ".specbridge/ledger/operations.ndjson"
  if (Test-Path $ledgerPath) {
    foreach ($line in (Get-Content $ledgerPath -Encoding UTF8)) {
      try { $obj = $line | ConvertFrom-Json; if ($null -ne $obj) { $ledgerEntries.Add($obj) } } catch {}
    }
  }
  $opCounts = @{}
  $runStats = @{ total=0; complete=0; in_progress=0 }
  $runIds = @{}
  foreach ($e in $ledgerEntries) {
    if (-not $opCounts.ContainsKey($e.operation)) { $opCounts[$e.operation] = @{ total=0; passed=0 } }
    $opCounts[$e.operation].total++
    if ($e.status -match "^(success|checks_passed|verified_existing|already_closed|already_merged|already_exists)$") {
      $opCounts[$e.operation].passed++
    }
    if ($e.run_id) {
      if (-not $runIds.ContainsKey($e.run_id)) { $runIds[$e.run_id] = @{ ops=@(); task_id=$e.task_id } }
      $runIds[$e.run_id].ops += $e.operation
    }
  }
  # Augment with scope-only runs (intake created but apply-mode not started yet)
  foreach ($sc in $scopes) {
    if ($sc.run_id -and -not $runIds.ContainsKey($sc.run_id)) {
      $runIds[$sc.run_id] = @{ ops=@(); task_id=$sc.contract_id }
    }
  }
  $runStats.total = $runIds.Count
  foreach ($rid in $runIds.Keys) {
    $ops = $runIds[$rid].ops
    if ($ops -contains "post_merge_memory") { $runStats.complete++ }
    else { $runStats.in_progress++ }
  }

  $currentGoalTaskId = "unknown"
  $currentGoalStatus = "unknown"
  $cgPath = Join-Path $repoRoot ".specbridge/state/current-goal.json"
  if (Test-Path $cgPath) {
    try {
      $cg = Get-Content $cgPath -Raw -Encoding UTF8 | ConvertFrom-Json
      $currentGoalTaskId = $cg.current_task_id
      $currentGoalStatus = $cg.status
    } catch {}
  }

  # Gather open lifecycle debt from GitHub
  $debtItems = [System.Collections.Generic.List[string]]::new()
  $previousEap = $ErrorActionPreference; $ErrorActionPreference = "Continue"
  $openPrsRaw = & gh pr list --repo $repoSlug --state open --json number,title,headRefName 2>&1
  $prFetchOk = $LASTEXITCODE
  $ErrorActionPreference = $previousEap
  $dashOpenPrs = @()
  $dashExecPrs = @()
  $dashMemoryPrs = @()
  if ($prFetchOk -eq 0) {
    try {
      $dashOpenPrs = @($openPrsRaw | ConvertFrom-Json)
      $dashExecPrs = @($dashOpenPrs | Where-Object { $_.headRefName -match "^codex/" })
      $dashMemoryPrs = @($dashOpenPrs | Where-Object { $_.headRefName -match "^specbridge/memory-closure-" })
      # Check ledger for issue_close vs open exec PR violations
      $ldgrPath2 = Join-Path $repoRoot ".specbridge/ledger/operations.ndjson"
      if (Test-Path $ldgrPath2) {
        foreach ($line in (Get-Content $ldgrPath2 -Encoding UTF8)) {
          try {
            $entry = $line | ConvertFrom-Json
            if ($null -eq $entry) { continue }
            if ($entry.operation -eq "issue_close" -and $entry.status -match "^(success|already_closed)$") {
              $matchingExec = @($dashExecPrs | Where-Object { $_.headRefName -match [regex]::Escape($entry.task_id) })
              if ($matchingExec.Count -gt 0) {
                $debtItems.Add("VIOLATION: issue_close for $($entry.task_id) but primary PR still open")
              }
            }
          } catch {}
        }
      }
      # Premature closure PRs
      foreach ($closurePr in $dashMemoryPrs) {
        $tid = $closurePr.headRefName -replace "^specbridge/memory-closure-", ""
        $matching = @($dashExecPrs | Where-Object { $_.headRefName -match [regex]::Escape($tid) })
        if ($matching.Count -gt 0) {
          $debtItems.Add("VIOLATION: memory-closure PR #$($closurePr.number) premature - primary PR not merged")
        }
      }
    } catch {}
  }
  $debtHtml = if ($debtItems.Count -eq 0) { "<p style='color:#2d9e5f'>No open lifecycle debt.</p>" } else {
    "<ul>" + ($debtItems | ForEach-Object {
      $color = if ($_ -match "^VIOLATION") { "#c0392b" } else { "#e6a817" }
      "<li style='color:$color'>$_</li>"
    } | Out-String -Stream | Where-Object { $_ -ne "" } | ForEach-Object { $_.Trim() } ) + "</ul>"
  }

  $opRows = ""
  foreach ($op in $opCounts.Keys) {
    $t = $opCounts[$op].total
    $p = $opCounts[$op].passed
    $rate = if ($t -gt 0) { [math]::Round(100 * $p / $t) } else { 0 }
    $color = if ($rate -ge 80) { "#2d9e5f" } elseif ($rate -ge 50) { "#e6a817" } else { "#c0392b" }
    $opRows += "<tr><td>$op</td><td>$p / $t</td><td style='color:$color'>$rate%</td></tr>"
  }

  $scopeRows = ""
  foreach ($s in ($scopes | Sort-Object { $_.status } -Descending)) {
    $badge = if ($s.status -eq "completed") { "<span style='color:#2d9e5f'>&#10003; completed</span>" } else { "<span style='color:#e6a817'>&#9654; active</span>" }
    $scopeRows += "<tr><td>$($s.contract_id)</td><td>$badge</td></tr>"
  }

  $generatedAt = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
  $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>SpecBridge Status Dashboard</title>
<style>
  body{font-family:system-ui,sans-serif;background:#0f1117;color:#e0e0e0;margin:0;padding:24px}
  h1{font-size:1.4rem;margin-bottom:4px}
  .sub{color:#888;font-size:.85rem;margin-bottom:24px}
  .grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:12px;margin-bottom:24px}
  .card{background:#1a1d27;border-radius:8px;padding:16px}
  .card .val{font-size:2rem;font-weight:700;margin:4px 0}
  .card .lbl{font-size:.8rem;color:#888}
  .healthy{color:#2d9e5f}.degraded{color:#e6a817}.blocked{color:#c0392b}
  .debt{background:#1a0f0f;border:1px solid #5a1a1a;border-radius:8px;padding:16px;margin-bottom:24px}
  .debt h2{color:#c0392b;margin:0 0 8px}
  .debt ul{margin:0;padding-left:20px}
  .debt li{margin:4px 0;font-size:.9rem}
  table{width:100%;border-collapse:collapse;background:#1a1d27;border-radius:8px;overflow:hidden;margin-bottom:24px}
  th{background:#23263a;padding:10px 14px;text-align:left;font-size:.8rem;color:#888}
  td{padding:10px 14px;border-top:1px solid #23263a;font-size:.85rem}
  h2{font-size:1rem;margin:20px 0 8px}
  .footer{color:#555;font-size:.75rem;margin-top:24px}
</style>
</head>
<body>
<h1>SpecBridge Status Dashboard</h1>
<p class="sub">Generated $generatedAt &mdash; repo: $repoSlug</p>

<div class="debt">
<h2>OPEN LIFECYCLE DEBT</h2>
$debtHtml
</div>

<div class="grid">
  <div class="card"><div class="val">$($completedScopes.Count)</div><div class="lbl">Completed Scopes</div></div>
  <div class="card"><div class="val">$($activeScopes.Count)</div><div class="lbl">Active Scopes</div></div>
  <div class="card"><div class="val">$($ledgerEntries.Count)</div><div class="lbl">Total Operations</div></div>
  <div class="card"><div class="val" title="$currentGoalTaskId">$currentGoalStatus</div><div class="lbl">Current Goal Status</div></div>
</div>
<div class="grid">
  <div class="card"><div class="val">$($runStats.total)</div><div class="lbl">Total Runs</div></div>
  <div class="card"><div class="val" style='color:#2d9e5f'>$($runStats.complete)</div><div class="lbl">Complete Runs</div></div>
  <div class="card"><div class="val" style='color:#e6a817'>$($runStats.in_progress)</div><div class="lbl">Runs In Progress</div></div>
</div>

<h2>Current Goal</h2>
<table><tr><th>Task ID</th><th>Status</th></tr>
<tr><td>$currentGoalTaskId</td><td>$currentGoalStatus</td></tr>
</table>

<h2>Operation Success Rates</h2>
<table><tr><th>Operation</th><th>Passed / Total</th><th>Rate</th></tr>
$opRows
</table>

<h2>Scopes</h2>
<table><tr><th>Contract ID</th><th>Status</th></tr>
$scopeRows
</table>

<p class="footer">SpecBridge &mdash; specbridge-generate-dashboard &mdash; $generatedAt</p>
</body>
</html>
"@

  $dashPath = Join-Path $repoRoot "docs/status-dashboard.html"
  Write-DashboardHtmlFile -Path $dashPath -Value $html

  Write-CliJson ([ordered]@{
    command   = "generate-dashboard"
    output    = "docs/status-dashboard.html"
    scopes    = $scopes.Count
    completed = $completedScopes.Count
    active    = $activeScopes.Count
    ledger_entries = $ledgerEntries.Count
    status    = "generated"
  })
  exit 0
}

function Invoke-GenerateStudioDashboardCommand {
  # ── Load current-goal ────────────────────────────────────────────────────
  $cgPath = Join-Path $repoRoot ".specbridge/state/current-goal.json"
  $cg = $null
  if (Test-Path $cgPath) {
    try { $cg = Get-Content $cgPath -Raw -Encoding UTF8 | ConvertFrom-Json } catch {}
  }
  $cgTaskId  = if ($cg -and $cg.current_task_id) { $cg.current_task_id } else { "none" }
  $cgTitle   = if ($cg -and $cg.title)    { $cg.title }    else { "" }
  $cgStatus  = if ($cg -and $cg.status)   { $cg.status }   else { "unknown" }
  $cgRunId   = if ($cg -and $cg.run_id)   { $cg.run_id }   else { "" }
  $cgPr      = if ($cg -and $cg.primary_pr) { $cg.primary_pr } else { "" }

  # ── Load scopes ──────────────────────────────────────────────────────────
  $scopes = [System.Collections.Generic.List[object]]::new()
  $scopeDir = Join-Path $repoRoot ".specbridge/scopes"
  if (Test-Path $scopeDir) {
    foreach ($sf in (Get-ChildItem $scopeDir -Filter "*.scope.json")) {
      try { $scopes.Add((Get-Content $sf.FullName -Raw -Encoding UTF8 | ConvertFrom-Json)) } catch {}
    }
  }
  $activeScopes    = @($scopes | Where-Object { $_.status -eq "active" })
  $completedScopes = @($scopes | Where-Object { $_.status -eq "completed" })

  # ── Load ledger ──────────────────────────────────────────────────────────
  $ledgerPath = Join-Path $repoRoot ".specbridge/ledger/operations.ndjson"
  $ledgerEntries = [System.Collections.Generic.List[object]]::new()
  $ledgerPresent = Test-Path $ledgerPath
  if ($ledgerPresent) {
    foreach ($line in (Get-Content $ledgerPath -Encoding UTF8)) {
      try { $obj = $line | ConvertFrom-Json; if ($null -ne $obj) { $ledgerEntries.Add($obj) } } catch {}
    }
  }

  # ── Build run map (run_id to {task_id, ops[]}) ──────────────────────────
  $runMap = @{}
  foreach ($e in $ledgerEntries) {
    if ($e.run_id) {
      if (-not $runMap.ContainsKey($e.run_id)) {
        $runMap[$e.run_id] = @{ task_id=$e.task_id; ops=[System.Collections.Generic.List[object]]::new() }
      }
      $runMap[$e.run_id].ops.Add(@{
        operation = $e.operation
        status    = $e.status
        timestamp = if ($e.timestamp) { $e.timestamp } else { "" }
      })
    }
  }
  # Augment: scopes with run_id not yet in ledger
  foreach ($sc in $scopes) {
    if ($sc.run_id -and -not $runMap.ContainsKey($sc.run_id)) {
      $runMap[$sc.run_id] = @{ task_id=$sc.contract_id; ops=[System.Collections.Generic.List[object]]::new() }
    }
  }

  # ── Closure evidence map ─────────────────────────────────────────────────
  $closureMap = @{}
  $evidenceDir = Join-Path $repoRoot ".specbridge/github-evidence"
  if (Test-Path $evidenceDir) {
    foreach ($cf in (Get-ChildItem $evidenceDir -Filter "*.closure.json")) {
      $tid = $cf.BaseName -replace "\.closure$", ""
      $closureMap[$tid] = $cf.FullName
    }
  }

  # ── Orchestrations ───────────────────────────────────────────────────────
  $orchestrations = [System.Collections.Generic.List[object]]::new()
  $orchDir3 = Join-Path $repoRoot ".specbridge/orchestrations"
  if (Test-Path $orchDir3) {
    foreach ($of in (Get-ChildItem $orchDir3 -Filter "*.orchestration.json" -ErrorAction SilentlyContinue)) {
      try { $orchestrations.Add((Get-Content $of.FullName -Raw -Encoding UTF8 | ConvertFrom-Json)) } catch {}
    }
  }

  # ── Fix-plan (offline) ───────────────────────────────────────────────────
  $fixPlanActions = @()
  try {
    $fpRaw = & $PSCommandPath -Command specbridge-doctor -FixPlan -Offline 2>&1
    if ($LASTEXITCODE -eq 0) {
      $fpJson = ($fpRaw | Out-String).Trim() | ConvertFrom-Json
      if ($fpJson.actions) { $fixPlanActions = @($fpJson.actions) }
    }
  } catch {}

  # ── Operator queue (next-task, offline) ──────────────────────────────────
  $queueInfo = $null
  try {
    $qRaw = & $PSCommandPath -Command specbridge-next-task 2>&1
    if ($LASTEXITCODE -eq 0) {
      $queueInfo = ($qRaw | Out-String).Trim() | ConvertFrom-Json
    }
  } catch {}

  # ── Build HTML ───────────────────────────────────────────────────────────
  $generatedAt = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
  $repoSlug    = ($RepositoryUrl -replace "https://github\.com/", "")

  # Current-goal section
  $cgPrLink = if ($cgPr) { "<a href='https://github.com/$repoSlug/pull/$cgPr' style='color:#7ab4f5'>#$cgPr</a>" } else { "&mdash;" }
  $cgRunDisplay = if ($cgRunId) { "<code>$cgRunId</code>" } else { "&mdash;" }
  $cgStatusColor = switch ($cgStatus) {
    "active"             { "#e6a817" }
    "ready_for_next_task"{ "#2d9e5f" }
    default              { "#888" }
  }
  $cgHtml = @"
<table><tr><th>Field</th><th>Value</th></tr>
<tr><td>Task ID</td><td><code>$cgTaskId</code></td></tr>
<tr><td>Title</td><td>$cgTitle</td></tr>
<tr><td>Status</td><td><span style='color:$cgStatusColor'>$cgStatus</span></td></tr>
<tr><td>Run ID</td><td>$cgRunDisplay</td></tr>
<tr><td>Primary PR</td><td>$cgPrLink</td></tr>
</table>
"@

  # Fix-plan alerts section
  $fpHtml = if ($fixPlanActions.Count -eq 0) {
    "<p style='color:#2d9e5f'>No fix-plan actions &ndash; plan is healthy.</p>"
  } else {
    $rows = ""
    foreach ($a in $fixPlanActions) {
      $sev = if ($a.severity) { $a.severity } else { "warning" }
      $sevColor = if ($sev -eq "error") { "#c0392b" } else { "#e6a817" }
      $tid = if ($a.task_id) { $a.task_id } else { "&mdash;" }
      $rows += "<tr><td style='color:$sevColor'>$sev</td><td><code>$($a.id)</code></td><td>$tid</td><td style='font-size:.8rem;color:#aaa'>$($a.diagnosis)</td></tr>"
    }
    "<table><tr><th>Severity</th><th>Action</th><th>Task</th><th>Diagnosis</th></tr>$rows</table>"
  }

  # Runs section
  $runsHtml = if ($runMap.Count -eq 0) {
    "<p style='color:#888'>No runs recorded.</p>"
  } else {
    $blocks = ""
    foreach ($rid in $runMap.Keys) {
      $entry     = $runMap[$rid]
      $tid       = $entry.task_id
      $ops       = @($entry.ops)
      $hasClosure= $closureMap.ContainsKey($tid)
      $closureBadge = if ($hasClosure) { "<span style='color:#2d9e5f'>&#10003; closure</span>" } else { "<span style='color:#888'>no closure</span>" }
      $opsComplete  = ($ops | Where-Object { $_.operation -eq "post_merge_memory" }).Count -gt 0
      $runStatusBadge = if ($opsComplete) { "<span style='color:#2d9e5f'>complete</span>" } else { "<span style='color:#e6a817'>in progress</span>" }
      $opRows = ""
      foreach ($op in $ops) {
        $sc = if ($op.status -match "^(success|checks_passed|verified_existing|already_closed|already_merged|already_exists|merge_completed)$") { "#2d9e5f" } else { "#c0392b" }
        $ts = if ($op.timestamp) { "<span style='color:#555;font-size:.75rem'>$($op.timestamp)</span>" } else { "" }
        $opRows += "<tr><td>$($op.operation)</td><td style='color:$sc'>$($op.status)</td><td>$ts</td></tr>"
      }
      $opTable = if ($opRows) {
        "<table style='margin-top:8px'><tr><th>Operation</th><th>Status</th><th>Timestamp</th></tr>$opRows</table>"
      } else {
        "<p style='color:#888;font-size:.85rem;margin:8px 0 0'>No ledger entries yet.</p>"
      }
      $blocks += @"
<div class='run-card'>
<div class='run-header'>
  <code class='run-id'>$rid</code>
  $runStatusBadge &nbsp; $closureBadge
</div>
<div class='run-task'>Task: <code>$tid</code></div>
$opTable
</div>
"@
    }
    $blocks
  }

  # Scopes section
  $scopeRows = ""
  foreach ($sc in ($scopes | Sort-Object { $_.status } -Descending)) {
    $badge = if ($sc.status -eq "completed") {
      "<span style='color:#2d9e5f'>&#10003; completed</span>"
    } else {
      "<span style='color:#e6a817'>&#9654; active</span>"
    }
    $runIdCell = if ($sc.run_id) { "<code style='font-size:.8rem'>$($sc.run_id)</code>" } else { "&mdash;" }
    $scopeRows += "<tr><td><code>$($sc.contract_id)</code></td><td>$badge</td><td>$runIdCell</td></tr>"
  }
  $scopeTableHtml = "<table><tr><th>Contract ID</th><th>Status</th><th>Run ID</th></tr>$scopeRows</table>"

  $ledgerNote = if (-not $ledgerPresent) {
    "<p style='color:#e6a817;font-size:.85rem'>&#9888; Ledger not found &ndash; first apply-mode run has not started.</p>"
  } else { "" }

  # Orchestrations section
  $queueSectionHtml = if (Get-Command Get-StudioOperatorQueueHtml -ErrorAction SilentlyContinue) {
    Get-StudioOperatorQueueHtml -RepositoryRoot $repoRoot
  } elseif ($null -eq $queueInfo) {
    "<p style='color:#888'>Operator queue state unavailable.</p>"
  } else {
    $qEligible = @($queueInfo.eligible_tasks).Count
    $qExcludedRows = ""
    foreach ($qx in @($queueInfo.excluded_issues)) {
      $qExcludedRows += "<tr><td>#$($qx.issue)</td><td><code>$($qx.task_id)</code></td><td style='color:#e6a817'>$($qx.reason)</td></tr>"
    }
    $qExcludedTable = if ($qExcludedRows -eq "") {
      "<p style='color:#2d9e5f'>No excluded issues.</p>"
    } else {
      "<table style='margin-top:8px'><tr><th>Issue</th><th>Task</th><th>Decision</th></tr>$qExcludedRows</table>"
    }
    $qActionColor = switch ($queueInfo.recommended_action) {
      "continue_current_goal"     { "#7ab4f5" }
      "execute_eligible_task"     { "#2d9e5f" }
      default                     { "#e6a817" }
    }
    "<p>Eligible tasks: <strong>$qEligible</strong> &nbsp; Excluded tasks: <strong>$(@($queueInfo.excluded_issues).Count)</strong> &nbsp; Recommended action: <strong style='color:$qActionColor'>$($queueInfo.recommended_action)</strong></p>$qExcludedTable"
  }

  $orchSectionHtml = if ($orchestrations.Count -eq 0) {
    "<p style='color:#888'>No orchestration manifests found.</p>"
  } else {
    $orchBlocks = ""
    foreach ($orch in $orchestrations) {
      $oStatus = if ($orch.status) { $orch.status } else { "unknown" }
      $oColor = switch ($oStatus) {
        "completed"   { "#2d9e5f" }
        "in_progress" { "#7ab4f5" }
        "cancelled"   { "#888" }
        default       { "#e6a817" }
      }
      $agentRows = ""
      foreach ($ag in $orch.agents) {
        $aColor = switch ($ag.status) {
          "completed" { "#2d9e5f" }
          "active"    { "#7ab4f5" }
          "failed"    { "#c0392b" }
          "skipped"   { "#888" }
          default     { "#555" }
        }
        $agentRows += "<tr><td><code>$($ag.name)</code></td><td style='color:$aColor'>$($ag.status)</td><td style='font-size:.8rem;color:#aaa'>$($ag.role)</td></tr>"
      }
      $reviewLine = ""
      $reviewReportPath = Join-Path $repoRoot ".specbridge/agent-reviews/$($orch.task_id).review-agent-report.json"
      if (Test-Path -LiteralPath $reviewReportPath -PathType Leaf) {
        try {
          $rv = Get-Content -LiteralPath $reviewReportPath -Raw -Encoding UTF8 | ConvertFrom-Json
          $rvColor = if ($rv.verdict -eq "approve") { "#2d9e5f" } else { "#c0392b" }
          $rvFindings = @($rv.findings).Count
          $reviewLine = "<div class='run-task'>Review: <span style='color:$rvColor'>$($rv.verdict)</span> ($rvFindings finding$(if ($rvFindings -ne 1) { 's' })) at <code>$($rv.reviewed_commit)</code></div>"
        } catch {}
      }
      $orchBlocks += "<div class='run-card'><div class='run-header'><code class='run-id'>$($orch.run_id)</code> <span style='color:$oColor'>$oStatus</span></div><div class='run-task'>Task: <code>$($orch.task_id)</code> &nbsp; Coordinator: $($orch.coordinator)</div>$reviewLine<table style='margin-top:8px'><tr><th>Agent</th><th>Status</th><th>Role</th></tr>$agentRows</table></div>"
    }
    $orchBlocks
  }

  $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>SpecBridge Studio</title>
<style>
  body{font-family:system-ui,sans-serif;background:#0f1117;color:#e0e0e0;margin:0;padding:24px}
  h1{font-size:1.5rem;margin-bottom:4px}
  h2{font-size:1rem;margin:28px 0 8px;color:#aaa;text-transform:uppercase;letter-spacing:.05em}
  .sub{color:#888;font-size:.85rem;margin-bottom:28px}
  .section{background:#1a1d27;border-radius:8px;padding:16px;margin-bottom:16px}
  table{width:100%;border-collapse:collapse;background:#1a1d27;border-radius:8px;overflow:hidden;margin-bottom:0}
  th{background:#23263a;padding:10px 14px;text-align:left;font-size:.78rem;color:#888;text-transform:uppercase}
  td{padding:9px 14px;border-top:1px solid #23263a;font-size:.85rem}
  code{background:#23263a;padding:2px 6px;border-radius:4px;font-size:.82em}
  .run-card{background:#1a1d27;border:1px solid #23263a;border-radius:8px;padding:16px;margin-bottom:12px}
  .run-header{display:flex;align-items:center;gap:12px;margin-bottom:6px}
  .run-id{font-size:.9rem;background:#23263a;padding:3px 8px;border-radius:4px}
  .run-task{font-size:.82rem;color:#888;margin-bottom:4px}
  .run-card table{background:#23263a}
  .run-card th{background:#2e3248}
  .fp-section{background:#1a1a0f;border:1px solid #4a4a1a;border-radius:8px;padding:16px;margin-bottom:16px}
  .fp-section table{background:#1a1a0f}
  .fp-section th{background:#2e2e18}
  .orch-section{background:#0f1a2e;border:1px solid #1a3a5a;border-radius:8px;padding:16px;margin-bottom:16px}
  .footer{color:#555;font-size:.75rem;margin-top:28px}
  a{color:#7ab4f5}
</style>
</head>
<body>
<h1>SpecBridge Studio</h1>
<p class="sub">Generated $generatedAt &mdash; repo: $repoSlug</p>

<h2>Current Goal</h2>
<div class="section">$cgHtml</div>

<h2>Fix-Plan Alerts</h2>
<div class="fp-section">$fpHtml</div>

$ledgerNote
<h2>Operator Queue</h2>
<div class="section">$queueSectionHtml</div>

<h2>Orchestrations ($($orchestrations.Count))</h2>
<div class="orch-section">$orchSectionHtml</div>

<h2>Runs ($($runMap.Count))</h2>
$runsHtml

<h2>Scopes ($($scopes.Count) total &mdash; $($activeScopes.Count) active, $($completedScopes.Count) completed)</h2>
<div class="section">$scopeTableHtml</div>

<p class="footer">SpecBridge Studio &mdash; generate-studio-dashboard &mdash; $generatedAt</p>
</body>
</html>
"@

  $outPath = Join-Path $repoRoot "docs/specbridge-studio.html"
  Write-DashboardHtmlFile -Path $outPath -Value $html

  Write-CliJson ([ordered]@{
    command        = "generate-studio-dashboard"
    output         = "docs/specbridge-studio.html"
    current_goal   = $cgTaskId
    runs           = $runMap.Count
    active_scopes  = $activeScopes.Count
    completed_scopes = $completedScopes.Count
    ledger_entries = $ledgerEntries.Count
    fix_plan_actions = $fixPlanActions.Count
    orchestrations = $orchestrations.Count
    status         = "generated"
  })
  exit 0
}

