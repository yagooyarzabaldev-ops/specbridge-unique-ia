<#
.SYNOPSIS
  SpecBridge Unique IA - provider-neutral single-agent governed lifecycle CLI.
.DESCRIPTION
  PowerShell 5.1 compatible, no external dependencies.
  All phases are dry-run by default. Pass -Apply to enable live provider calls.
.PARAMETER Command
  doctor | plan | implement | validate | review | close
.PARAMETER TaskId
  Task identifier (required for all phases except doctor).
.PARAMETER Title
  Task title (required for plan).
.PARAMETER Goal
  Task goal (required for plan).
.PARAMETER Apply
  Enable live provider invocation. Default is dry-run.
.EXAMPLE
  .\scripts\unique-ai.ps1 doctor
  .\scripts\unique-ai.ps1 plan -TaskId my-task -Title "My Task" -Goal "Describe the goal"
  .\scripts\unique-ai.ps1 implement -TaskId my-task -Apply
#>
param(
    [Parameter(Position = 0, Mandatory = $false)]
    [string]$Command = '',

    [string]$TaskId = '',
    [string]$Title  = '',
    [string]$Goal   = '',
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'

$REPO_ROOT = Split-Path $PSScriptRoot -Parent

. (Join-Path $PSScriptRoot 'lib\unique-ai-common.ps1')
. (Join-Path $PSScriptRoot 'lib\unique-ai-provider.ps1')
. (Join-Path $PSScriptRoot 'lib\unique-ai-lifecycle.ps1')

$DryRun = -not $Apply.IsPresent

# ── doctor ──────────────────────────────────────────────────────────────────

function Invoke-Doctor {
    $config     = Get-UniqueAIConfig
    $configPath = Get-UniqueAIConfigPath

    $configStatus = if ($null -eq $config) { 'missing' } else { 'ok' }
    $providerStatus = Test-UniqueAIProviderReady -Config $config

    $runsDir     = Join-Path $REPO_ROOT '.unique-ai\runs'
    $activeTasks = @()
    if (Test-Path $runsDir) {
        $activeTasks = @(Get-ChildItem $runsDir -Directory -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty Name)
    }

    $data = @{
        config_path         = $configPath
        config_status       = $configStatus
        provider_id         = $(if ($config) { $config.provider.provider_id } else { $null })
        model               = $(if ($config) { $config.provider.model } else { $null })
        provider_executable = $(if ($config) { $config.provider.executable } else { $null })
        provider_ready      = $providerStatus.ready
        provider_reason     = $providerStatus.reason
        dry_run_default     = $true
        active_tasks        = $activeTasks
        active_task_count   = $activeTasks.Count
        repo_root           = $REPO_ROOT
        policy              = 'no_autonomous_merge, no_production, no_secrets, no_deployment'
        review_label        = 'fresh_session_self_review'
    }

    $result = New-UniqueAIResult -Command 'doctor' -Ok $true -Data $data
    Out-CliJson -Value $result
}

# ── plan ────────────────────────────────────────────────────────────────────

function Invoke-Plan {
    if ([string]::IsNullOrWhiteSpace($TaskId)) {
        Out-CliJson -Value (New-UniqueAIResult -Command 'plan' -Ok $false -Message '-TaskId is required')
        exit 1
    }
    if ([string]::IsNullOrWhiteSpace($Title)) {
        Out-CliJson -Value (New-UniqueAIResult -Command 'plan' -Ok $false -Message '-Title is required')
        exit 1
    }
    if ([string]::IsNullOrWhiteSpace($Goal)) {
        Out-CliJson -Value (New-UniqueAIResult -Command 'plan' -Ok $false -Message '-Goal is required')
        exit 1
    }

    $config = Get-UniqueAIConfig

    try {
        $r = Invoke-UniqueAIPlan -TaskId $TaskId -Title $Title -Goal $Goal -Config $config -DryRun $DryRun
        Out-CliJson -Value (New-UniqueAIResult -Command 'plan' -Ok $r.ok -Data @{
            task_id    = $r.task_id
            dry_run    = $r.dry_run
            artifact   = $r.artifact
            status     = $r.status
            next_phase = $r.next_phase
        })
        if (-not $r.ok) { exit 1 }
    } catch {
        Out-CliJson -Value (New-UniqueAIResult -Command 'plan' -Ok $false -Message $_.Exception.Message)
        exit 1
    }
}

# ── implement ────────────────────────────────────────────────────────────────

function Invoke-Implement {
    if ([string]::IsNullOrWhiteSpace($TaskId)) {
        Out-CliJson -Value (New-UniqueAIResult -Command 'implement' -Ok $false -Message '-TaskId is required')
        exit 1
    }
    $config = Get-UniqueAIConfig
    try {
        $r = Invoke-UniqueAIImplement -TaskId $TaskId -Config $config -DryRun $DryRun
        Out-CliJson -Value (New-UniqueAIResult -Command 'implement' -Ok $r.ok -Data @{
            task_id    = $r.task_id
            dry_run    = $r.dry_run
            artifact   = $r.artifact
            status     = $r.status
            next_phase = $r.next_phase
        })
        if (-not $r.ok) { exit 1 }
    } catch {
        Out-CliJson -Value (New-UniqueAIResult -Command 'implement' -Ok $false -Message $_.Exception.Message)
        exit 1
    }
}

# ── validate ─────────────────────────────────────────────────────────────────

function Invoke-Validate {
    if ([string]::IsNullOrWhiteSpace($TaskId)) {
        Out-CliJson -Value (New-UniqueAIResult -Command 'validate' -Ok $false -Message '-TaskId is required')
        exit 1
    }
    $config = Get-UniqueAIConfig
    try {
        $r = Invoke-UniqueAIValidate -TaskId $TaskId -Config $config -DryRun $DryRun
        Out-CliJson -Value (New-UniqueAIResult -Command 'validate' -Ok $r.ok -Data @{
            task_id    = $r.task_id
            dry_run    = $r.dry_run
            artifact   = $r.artifact
            status     = $r.status
            next_phase = $r.next_phase
        })
        if (-not $r.ok) { exit 1 }
    } catch {
        Out-CliJson -Value (New-UniqueAIResult -Command 'validate' -Ok $false -Message $_.Exception.Message)
        exit 1
    }
}

# ── review ───────────────────────────────────────────────────────────────────

function Invoke-Review {
    if ([string]::IsNullOrWhiteSpace($TaskId)) {
        Out-CliJson -Value (New-UniqueAIResult -Command 'review' -Ok $false -Message '-TaskId is required')
        exit 1
    }
    $config = Get-UniqueAIConfig
    try {
        $r = Invoke-UniqueAIReview -TaskId $TaskId -Config $config -DryRun $DryRun
        Out-CliJson -Value (New-UniqueAIResult -Command 'review' -Ok $r.ok -Data @{
            task_id      = $r.task_id
            dry_run      = $r.dry_run
            artifact     = $r.artifact
            status       = $r.status
            review_label = $r.review_label
            next_phase   = $r.next_phase
        })
        if (-not $r.ok) { exit 1 }
    } catch {
        Out-CliJson -Value (New-UniqueAIResult -Command 'review' -Ok $false -Message $_.Exception.Message)
        exit 1
    }
}

# ── close ─────────────────────────────────────────────────────────────────────

function Invoke-Close {
    if ([string]::IsNullOrWhiteSpace($TaskId)) {
        Out-CliJson -Value (New-UniqueAIResult -Command 'close' -Ok $false -Message '-TaskId is required')
        exit 1
    }
    $config = Get-UniqueAIConfig
    try {
        $r = Invoke-UniqueAIClose -TaskId $TaskId -Config $config -DryRun $DryRun
        Out-CliJson -Value (New-UniqueAIResult -Command 'close' -Ok $r.ok -Data @{
            task_id  = $r.task_id
            dry_run  = $r.dry_run
            artifact = $r.artifact
            status   = $r.status
        })
        if (-not $r.ok) { exit 1 }
    } catch {
        Out-CliJson -Value (New-UniqueAIResult -Command 'close' -Ok $false -Message $_.Exception.Message)
        exit 1
    }
}

function Invoke-Run {
    if ([string]::IsNullOrWhiteSpace($TaskId) -or [string]::IsNullOrWhiteSpace($Title) -or [string]::IsNullOrWhiteSpace($Goal)) {
        Out-CliJson -Value (New-UniqueAIResult -Command 'run' -Ok $false -Message '-TaskId, -Title, and -Goal are required')
        exit 1
    }
    $config = Get-UniqueAIConfig
    try {
        $phases = @()
        $phases += Invoke-UniqueAIPlan -TaskId $TaskId -Title $Title -Goal $Goal -Config $config -DryRun $DryRun
        if (-not $phases[-1].ok) { throw 'Plan phase failed.' }
        $phases += Invoke-UniqueAIImplement -TaskId $TaskId -Config $config -DryRun $DryRun
        if (-not $phases[-1].ok) { throw 'Implement phase failed.' }
        $phases += Invoke-UniqueAIValidate -TaskId $TaskId -Config $config -DryRun $DryRun
        if (-not $phases[-1].ok) { throw 'Validate/fix phase failed.' }
        $phases += Invoke-UniqueAIReview -TaskId $TaskId -Config $config -DryRun $DryRun
        if (-not $phases[-1].ok) { throw 'Fresh-session self-review failed.' }
        $phases += Invoke-UniqueAIClose -TaskId $TaskId -Config $config -DryRun $DryRun
        if (-not $phases[-1].ok) { throw 'Close phase failed.' }
        Out-CliJson -Value (New-UniqueAIResult -Command 'run' -Ok $true -Data @{ task_id = $TaskId; dry_run = $DryRun; phases = $phases; status = $(if ($DryRun) { 'dry_run_complete' } else { 'completed' }) }) -Depth 12
    } catch {
        Out-CliJson -Value (New-UniqueAIResult -Command 'run' -Ok $false -Message $_.Exception.Message -Data @{ task_id = $TaskId; dry_run = $DryRun })
        exit 1
    }
}

# ── dispatch ──────────────────────────────────────────────────────────────────

switch ($Command.ToLower()) {
    'doctor'    { Invoke-Doctor }
    'plan'      { Invoke-Plan }
    'implement' { Invoke-Implement }
    'validate'  { Invoke-Validate }
    'review'    { Invoke-Review }
    'close'     { Invoke-Close }
    'run'       { Invoke-Run }
    default {
        Out-CliJson -Value (New-UniqueAIResult -Command 'help' -Ok $true -Data @{
            product  = 'SpecBridge Unique IA'
            commands = @('doctor', 'plan', 'implement', 'validate', 'review', 'close', 'run')
            usage    = '.\scripts\unique-ai.ps1 <command> [options]'
            options  = [ordered]@{
                '-TaskId'           = 'Task identifier (all phases except doctor)'
                '-Title'            = 'Task title (plan)'
                '-Goal'             = 'Task goal description (plan)'
                '-Apply'            = 'Enable live provider invocation (default: dry-run)'
            }
            note = 'All phases are dry-run by default. Pass -Apply for live execution.'
        })
    }
}
