# unique-ai-common.ps1 - Shared utilities for Unique IA CLI
# Dot-sourced by scripts/unique-ai.ps1. Do not run directly.
# Requires: $REPO_ROOT must be set by the caller before dot-sourcing.

function Write-Utf8JsonFile {
    param([string]$Path, [object]$Value, [int]$Depth = 8)
    $dir = Split-Path $Path -Parent
    if ($dir -and -not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $json = $Value | ConvertTo-Json -Depth $Depth
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $json, $utf8NoBom)
}

function Read-Utf8JsonFile {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $null }
    $text = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    return $text | ConvertFrom-Json
}

function Out-CliJson {
    param([object]$Value, [int]$Depth = 8)
    Write-Output ($Value | ConvertTo-Json -Depth $Depth)
}

function Get-UniqueAIRunDir {
    param([string]$TaskId)
    return Join-Path $REPO_ROOT ".unique-ai\runs\$TaskId"
}

function Get-UniqueAIConfigPath {
    return Join-Path $REPO_ROOT ".unique-ai\config.json"
}

function Get-UniqueAIArtifact {
    param([string]$TaskId, [string]$Name)
    $path = Join-Path (Get-UniqueAIRunDir -TaskId $TaskId) "$Name.json"
    if (-not (Test-Path -LiteralPath $path)) { return $null }
    return Read-Utf8JsonFile -Path $path
}

function Assert-PhaseSucceeded {
    param([string]$TaskId, [string]$Phase)
    $artifact = Get-UniqueAIArtifact -TaskId $TaskId -Name $Phase
    if ($null -eq $artifact -or $artifact.status -notin @('completed', 'passed')) {
        throw "Required phase '$Phase' has not completed successfully for task '$TaskId'."
    }
}

function Assert-SafeTaskId {
    param([string]$TaskId)
    if ([string]::IsNullOrWhiteSpace($TaskId)) {
        throw "TaskId is required"
    }
    if ($TaskId -notmatch '^[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}$') {
        throw "TaskId must match ^[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}`$: $TaskId"
    }
}

function Test-BlockedPath {
    param([string[]]$BlockedPatterns, [string]$Path)
    $normalizedPath = $Path.Replace('\', '/')
    foreach ($pattern in $BlockedPatterns) {
        $regexPattern = '^' + [regex]::Escape($pattern).Replace('\*\*', '.*').Replace('\*', '[^/]*') + '$'
        if ($normalizedPath -match $regexPattern) {
            return $true
        }
    }
    return $false
}

function New-UniqueAIResult {
    param(
        [string]$Command,
        [bool]$Ok,
        [string]$Message = '',
        [hashtable]$Data = @{}
    )
    $result = [ordered]@{
        command   = $Command
        ok        = $Ok
        timestamp = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
    }
    if ($Message -ne '') { $result.message = $Message }
    foreach ($k in $Data.Keys) { $result[$k] = $Data[$k] }
    return $result
}
