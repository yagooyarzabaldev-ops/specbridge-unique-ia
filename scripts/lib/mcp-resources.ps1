# SpecBridge CLI library: mcp-resources
# Dot-sourced by scripts/specbridge.ps1. Do not run directly.

function Get-McpCurrentGoalResource {
  $sourcePath = ".specbridge/state/current-goal.json"
  $fullPath = Join-Path $repoRoot $sourcePath
  $content = $null
  if (Test-Path -LiteralPath $fullPath) {
    $raw = [System.IO.File]::ReadAllText($fullPath, [System.Text.Encoding]::UTF8)
    try { $content = $raw | ConvertFrom-Json } catch {}
  }
  return [ordered]@{
    name             = "specbridge://operator/current-goal"
    uri              = "specbridge://operator/current-goal"
    content_type     = "application/json"
    source_paths     = @(".specbridge/state/current-goal.json", ".specbridge/context/CURRENT_GOAL.md")
    refresh_behavior = "on_demand"
    sensitivity      = "internal"
    read_only        = $true
    description      = "Machine-readable current SpecBridge operator goal and task status."
    data             = $content
  }
}

function Get-McpDoctorFixPlanResource {
  $content = Get-McpDoctorFixPlanSnapshot
  return [ordered]@{
    name             = "specbridge://operator/doctor-fix-plan"
    uri              = "specbridge://operator/doctor-fix-plan"
    content_type     = "application/json"
    source_paths     = @(
      "scripts/lib/intake-doctor.ps1",
      ".specbridge/scopes/*.scope.json",
      ".specbridge/ledger/operations.ndjson",
      ".specbridge/github-evidence/*.json",
      ".specbridge/state/current-goal.json",
      "docs/status-dashboard.html"
    )
    refresh_behavior = "on_demand"
    sensitivity      = "internal"
    read_only        = $true
    description      = "Offline specbridge-doctor fix-plan output: detected drift classes, severity, repair commands, and safe_to_automate flags."
    data             = $content
  }
}

function Get-McpDoctorFixPlanSnapshot {
  $specbridgeScript = Join-Path $repoRoot "scripts/specbridge.ps1"
  if (-not (Test-Path -LiteralPath $specbridgeScript)) {
    return [ordered]@{
      command = "specbridge-doctor"
      ok      = $false
      error   = "scripts/specbridge.ps1 not found"
    }
  }

  $previousEap = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  $rawOutput = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $specbridgeScript specbridge-doctor -FixPlan -Offline 2>&1
  $exitCode = $LASTEXITCODE
  $ErrorActionPreference = $previousEap

  if ($exitCode -ne 0) {
    return [ordered]@{
      command   = "specbridge-doctor"
      ok        = $false
      exit_code = $exitCode
      error     = (($rawOutput | ForEach-Object { "$_" }) -join "`n").Trim()
    }
  }

  $rawText = (($rawOutput | ForEach-Object { "$_" }) -join "`n").Trim()
  try {
    return ($rawText | ConvertFrom-Json)
  } catch {
    return [ordered]@{
      command = "specbridge-doctor"
      ok      = $false
      error   = "Unable to parse offline fix-plan JSON"
      raw     = $rawText
    }
  }
}

function Get-McpOrchestrationSummariesResource {
  $orchDir = Join-Path $repoRoot ".specbridge/orchestrations"
  $summaries = @()
  if (Test-Path -LiteralPath $orchDir) {
    $orchFiles = Get-ChildItem -LiteralPath $orchDir -Filter "*.orchestration.json" -ErrorAction SilentlyContinue
    foreach ($f in $orchFiles) {
      $item = $null
      try {
        $raw = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
        $item = $raw | ConvertFrom-Json
      } catch {}
      if ($null -ne $item) {
        $summaries += [ordered]@{
          task_id    = $item.task_id
          status     = $item.status
          run_id     = $item.run_id
          created_at = $item.created_at
          source     = ".specbridge/orchestrations/$($f.Name)"
        }
      }
    }
  }
  return [ordered]@{
    name             = "specbridge://operator/orchestration-summaries"
    uri              = "specbridge://operator/orchestration-summaries"
    content_type     = "application/json"
    source_paths     = @(".specbridge/orchestrations/*.orchestration.json")
    refresh_behavior = "on_demand"
    sensitivity      = "internal"
    read_only        = $true
    description      = "Summarized view of all SpecBridge orchestration manifests: task_id, status, run_id, and created_at per orchestration."
    data             = $summaries
  }
}

function Build-McpResourceCatalog {
  $resources = @(
    (Get-McpCurrentGoalResource),
    (Get-McpDoctorFixPlanResource),
    (Get-McpOrchestrationSummariesResource)
  )
  return [ordered]@{
    schema_version      = "1"
    catalog_id          = "specbridge-operator-state"
    generated_at        = (Get-Date -Format "o")
    mcp_server_status   = "readonly_local_runtime"
    mcp_server_note     = "Bounded local MCP-style runtime: resources/list, resources/read, tools/list, and tools/call for explicitly allowlisted read-only local tools. No network transport, no mutation, no secrets, no server process."
    read_only_policy    = $true
    resources           = $resources
  }
}

$script:McpSupportedMethods = @("resources/list", "resources/read", "tools/list", "tools/call")

$script:McpBlockedMethods = @(
  "resources/create", "resources/update", "resources/delete", "resources/write",
  "resources/subscribe", "resources/unsubscribe",
  "prompts/get", "prompts/list",
  "sampling/createMessage",
  "logging/setLevel",
  "completion/complete",
  "initialize", "initialized", "shutdown", "exit",
  "ping"
)

$script:McpKnownUris = @(
  "specbridge://operator/current-goal",
  "specbridge://operator/doctor-fix-plan",
  "specbridge://operator/orchestration-summaries"
)

function Invoke-McpRuntimeCommand {
  if ([string]::IsNullOrWhiteSpace($Method)) {
    Fail "Method is required for specbridge-mcp-runtime. Supported: $($script:McpSupportedMethods -join ', ')"
  }

  if ($script:McpBlockedMethods -contains $Method) {
    Write-CliJson ([ordered]@{
      command         = "specbridge-mcp-runtime"
      ok              = $false
      error           = "method_not_allowed"
      method          = $Method
      detail          = "This method is blocked by the read-only MCP runtime policy."
      allowed_methods = $script:McpSupportedMethods
    })
    exit 1
  }

  if ($Method -eq "resources/list") {
    $resources = @(
      [ordered]@{
        uri         = "specbridge://operator/current-goal"
        name        = "specbridge://operator/current-goal"
        description = "Machine-readable current SpecBridge operator goal and task status."
        mimeType    = "application/json"
      },
      [ordered]@{
        uri         = "specbridge://operator/doctor-fix-plan"
        name        = "specbridge://operator/doctor-fix-plan"
        description = "Offline specbridge-doctor fix-plan output: detected drift classes, severity, repair commands, and safe_to_automate flags."
        mimeType    = "application/json"
      },
      [ordered]@{
        uri         = "specbridge://operator/orchestration-summaries"
        name        = "specbridge://operator/orchestration-summaries"
        description = "Summarized view of all SpecBridge orchestration manifests: task_id, status, run_id, and created_at."
        mimeType    = "application/json"
      }
    )
    Write-CliJson ([ordered]@{
      command = "specbridge-mcp-runtime"
      ok      = $true
      method  = "resources/list"
      result  = [ordered]@{
        resources = $resources
      }
    }) -Depth 8
    return
  }

  if ($Method -eq "resources/read") {
    if ([string]::IsNullOrWhiteSpace($Uri)) {
      Fail "Uri is required for resources/read"
    }
    $normalizedUri = $Uri.Trim()
    if ($script:McpKnownUris -notcontains $normalizedUri) {
      Write-CliJson ([ordered]@{
        command    = "specbridge-mcp-runtime"
        ok         = $false
        error      = "resource_not_found"
        uri        = $normalizedUri
        detail     = "Unknown resource URI. Use resources/list to see available URIs."
        known_uris = $script:McpKnownUris
      })
      exit 1
    }
    $resource = switch ($normalizedUri) {
      "specbridge://operator/current-goal"            { Get-McpCurrentGoalResource }
      "specbridge://operator/doctor-fix-plan"         { Get-McpDoctorFixPlanResource }
      "specbridge://operator/orchestration-summaries" { Get-McpOrchestrationSummariesResource }
    }
    Write-CliJson ([ordered]@{
      command = "specbridge-mcp-runtime"
      ok      = $true
      method  = "resources/read"
      uri     = $normalizedUri
      result  = [ordered]@{
        contents = @([ordered]@{
          uri      = $resource.uri
          mimeType = $resource.content_type
          text     = ($resource.data | ConvertTo-Json -Depth 10 -Compress)
        })
      }
    }) -Depth 10
    return
  }

  if ($Method -eq "tools/list") {
    Invoke-McpToolsListMethod
    return
  }

  if ($Method -eq "tools/call") {
    Invoke-McpToolsCallMethod
    return
  }

  # Unrecognised method that is not in the blocked list
  Write-CliJson ([ordered]@{
    command         = "specbridge-mcp-runtime"
    ok              = $false
    error           = "method_not_found"
    method          = $Method
    detail          = "Unknown MCP method."
    allowed_methods = $script:McpSupportedMethods
  })
  exit 1
}

function Invoke-McpResourcesCommand {
  $catalog = Build-McpResourceCatalog

  if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $expectedPath = ".specbridge/mcp-resources/operator-state.catalog.json"
    $normalized = Normalize-RepoPath -Path $OutputPath -FieldName "OutputPath"
    if ($normalized -ne $expectedPath) {
      Fail "OutputPath must be $expectedPath`: $normalized"
    }
    $fullOutputPath = Join-Path $repoRoot $normalized
    if ((Test-Path -LiteralPath $fullOutputPath) -and -not $Force) {
      Fail "OutputPath already exists; use -Force to replace it: $normalized"
    }
    Write-Utf8JsonFile -Path $normalized -Value $catalog -Depth 10
    Write-CliJson ([ordered]@{
      command     = "specbridge-mcp-resources"
      ok          = $true
      output_path = $normalized
      catalog     = $catalog
    })
    return
  }

  Write-CliJson ([ordered]@{
    command = "specbridge-mcp-resources"
    ok      = $true
    catalog = $catalog
  })
}
