# SpecBridge CLI library: mcp-tools
# Dot-sourced by scripts/specbridge.ps1. Do not run directly.

$script:McpAllowedTools = @(
  [ordered]@{
    name = "specbridge.operator.status"
    description = "Returns a read-only local summary of the current SpecBridge operator status: current goal, offline doctor fix-plan snapshot, and standard readiness posture. Does not write files or mutate state."
    inputSchema = [ordered]@{
      type       = "object"
      properties = [ordered]@{}
      required   = @()
    }
    annotations = [ordered]@{
      readOnlyHint = $true
    }
  },
  [ordered]@{
    name = "specbridge.next-task"
    description = "Returns the full read-only local next-task selector snapshot: current goal status, current task id, eligible tasks, excluded issues, and recommended action. Does not write files or mutate state."
    inputSchema = [ordered]@{
      type       = "object"
      properties = [ordered]@{}
      required   = @()
    }
    annotations = [ordered]@{
      readOnlyHint = $true
    }
  }
)

function Get-McpOperatorStatusToolResult {
  $currentGoalPath = Join-Path $repoRoot ".specbridge/state/current-goal.json"
  $currentGoal = $null
  if (Test-Path -LiteralPath $currentGoalPath) {
    try {
      $raw = [System.IO.File]::ReadAllText($currentGoalPath, [System.Text.Encoding]::UTF8)
      $currentGoal = $raw | ConvertFrom-Json
    } catch {}
  }

  $doctorSnapshot = Get-McpDoctorFixPlanSnapshot
  $nextTask       = Get-StandardReadinessNextTaskSnapshot

  return [ordered]@{
    tool = "specbridge.operator.status"
    current_goal = [ordered]@{
      current_task_id     = if ($null -ne $currentGoal) { $currentGoal.current_task_id } else { $null }
      status              = if ($null -ne $currentGoal) { $currentGoal.status }          else { "unknown" }
      last_completed_task = if ($null -ne $currentGoal) { $currentGoal.last_completed_task_id } else { $null }
      last_updated        = if ($null -ne $currentGoal) { $currentGoal.last_updated } else { $null }
    }
    doctor_fix_plan = [ordered]@{
      health        = if ($doctorSnapshot.PSObject.Properties.Name -contains "health")       { [string] $doctorSnapshot.health } else { "unknown" }
      action_count  = if ($doctorSnapshot.PSObject.Properties.Name -contains "action_count") { [int]    $doctorSnapshot.action_count } else { 0 }
      blocker_count = @($doctorSnapshot.blockers).Count
      warning_count = @($doctorSnapshot.warnings).Count
    }
    standard_readiness = [ordered]@{
      recommended_action   = [string] $nextTask.recommended_action
      current_goal_status  = [string] $nextTask.current_goal_status
      eligible_task_count  = @($nextTask.eligible_tasks).Count
      excluded_issue_count = @($nextTask.excluded_issues).Count
    }
    note = "Read-only local operator status snapshot. No files were written."
  }
}

function Get-McpNextTaskToolResult {
  $nextTask = Get-StandardReadinessNextTaskSnapshot

  return [ordered]@{
    tool                = "specbridge.next-task"
    current_goal_status = [string] $nextTask.current_goal_status
    current_task_id     = [string] $nextTask.current_task_id
    eligible_tasks      = @($nextTask.eligible_tasks)
    excluded_issues     = @($nextTask.excluded_issues)
    recommended_action  = [string] $nextTask.recommended_action
    note                = "Read-only local next-task selector snapshot. No files were written."
  }
}

function Invoke-McpToolsListMethod {
  Write-CliJson ([ordered]@{
    command = "specbridge-mcp-runtime"
    ok      = $true
    method  = "tools/list"
    result  = [ordered]@{
      tools = $script:McpAllowedTools
    }
  }) -Depth 8
}

function Invoke-McpToolsCallMethod {
  if ([string]::IsNullOrWhiteSpace($ToolName)) {
    Write-CliJson ([ordered]@{
      command       = "specbridge-mcp-runtime"
      ok            = $false
      error         = "tool_name_required"
      method        = "tools/call"
      detail        = "ToolName is required for tools/call. Use tools/list to see available tools."
      allowed_tools = @($script:McpAllowedTools | ForEach-Object { $_.name })
    })
    exit 1
  }

  $normalizedToolName = $ToolName.Trim()
  $allowedToolNames   = @($script:McpAllowedTools | ForEach-Object { $_.name })

  if ($allowedToolNames -notcontains $normalizedToolName) {
    Write-CliJson ([ordered]@{
      command       = "specbridge-mcp-runtime"
      ok            = $false
      error         = "tool_not_allowed"
      method        = "tools/call"
      tool          = $normalizedToolName
      detail        = "Tool is not in the local MCP tools allowlist. Use tools/list to see available tools."
      allowed_tools = $allowedToolNames
    })
    exit 1
  }

  if ($normalizedToolName -eq "specbridge.operator.status") {
    $toolResult = Get-McpOperatorStatusToolResult
    Write-CliJson ([ordered]@{
      command = "specbridge-mcp-runtime"
      ok      = $true
      method  = "tools/call"
      tool    = $normalizedToolName
      result  = [ordered]@{
        content = @(
          [ordered]@{
            type = "text"
            text = ($toolResult | ConvertTo-Json -Depth 10 -Compress)
          }
        )
      }
    }) -Depth 10
    return
  }

  if ($normalizedToolName -eq "specbridge.next-task") {
    $toolResult = Get-McpNextTaskToolResult
    Write-CliJson ([ordered]@{
      command = "specbridge-mcp-runtime"
      ok      = $true
      method  = "tools/call"
      tool    = $normalizedToolName
      result  = [ordered]@{
        content = @(
          [ordered]@{
            type = "text"
            text = ($toolResult | ConvertTo-Json -Depth 10 -Compress)
          }
        )
      }
    }) -Depth 10
    return
  }

  Write-CliJson ([ordered]@{
    command       = "specbridge-mcp-runtime"
    ok            = $false
    error         = "tool_not_allowed"
    method        = "tools/call"
    tool          = $normalizedToolName
    detail        = "Tool is not in the local MCP tools allowlist."
    allowed_tools = $allowedToolNames
  })
  exit 1
}
