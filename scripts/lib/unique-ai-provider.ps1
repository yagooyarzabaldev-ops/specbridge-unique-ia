# Provider-neutral, process-based adapter. Prompts are sent through stdin; no eval.

function Get-UniqueAIConfig {
    $configPath = Get-UniqueAIConfigPath
    if (-not (Test-Path -LiteralPath $configPath)) { return $null }
    return Read-Utf8JsonFile -Path $configPath
}

function Assert-UniqueAIConfig {
    param([object]$Config)
    if ($null -eq $Config) { throw 'Unique IA config is missing.' }
    foreach ($value in @($Config.provider.provider_id, $Config.provider.model, $Config.provider.executable)) {
        if ([string]::IsNullOrWhiteSpace([string]$value)) { throw 'provider_id, model, and executable are required.' }
    }
    $limits = $Config.limits
    if ([int]$limits.max_retries -lt 0 -or [int]$limits.max_retries -gt 3) { throw 'max_retries must be between 0 and 3.' }
    if ([int]$limits.timeout_seconds -lt 1 -or [int]$limits.timeout_seconds -gt 1800) { throw 'timeout_seconds must be between 1 and 1800.' }
    if ([double]$limits.budget_usd -le 0 -or [double]$limits.estimated_cost_per_invocation_usd -le 0) { throw 'Budget values must be positive.' }
    if ([int]$limits.max_invocations -lt 1) { throw 'max_invocations must be positive.' }
}

function Get-ProviderIdentity {
    param([object]$Config)
    return [ordered]@{ provider_id = [string]$Config.provider.provider_id; model = [string]$Config.provider.model }
}

function Test-UniqueAIProviderReady {
    param([object]$Config)
    try { Assert-UniqueAIConfig -Config $Config } catch { return [ordered]@{ ready = $false; reason = $_.Exception.Message } }
    $found = Get-Command ([string]$Config.provider.executable) -ErrorAction SilentlyContinue
    if ($null -eq $found) { return [ordered]@{ ready = $false; reason = 'executable_not_found' } }
    return [ordered]@{ ready = $true; reason = 'ok'; executable = $found.Source }
}

function Assert-ProviderIdentityLock {
    param([object]$Config, [object]$PlanArtifact)
    Assert-UniqueAIConfig -Config $Config
    if ($null -eq $PlanArtifact -or $null -eq $PlanArtifact.provider_identity) { throw 'Plan provider identity is missing.' }
    $expected = Get-ProviderIdentity -Config $Config
    if ($expected.provider_id -ne [string]$PlanArtifact.provider_identity.provider_id -or
        $expected.model -ne [string]$PlanArtifact.provider_identity.model) {
        throw 'Provider identity lock violation: provider_id and model must remain unchanged for every phase.'
    }
}

function ConvertTo-ProcessArguments {
    param([object[]]$Arguments)
    $encoded = @()
    foreach ($argument in @($Arguments)) {
        $text = [string]$argument
        if ($text -match '[\s"]') { $encoded += ('"' + $text.Replace('\', '\\').Replace('"', '\"') + '"') }
        else { $encoded += $text }
    }
    return ($encoded -join ' ')
}

function Get-UsageState {
    param([string]$TaskId)
    $path = Join-Path (Get-UniqueAIRunDir -TaskId $TaskId) 'usage.json'
    $state = Read-Utf8JsonFile -Path $path
    if ($null -eq $state) { $state = [ordered]@{ invocations = 0; estimated_spend_usd = 0.0 } }
    return [ordered]@{ path = $path; state = $state }
}

function Invoke-UniqueAIProvider {
    param([object]$Config, [string]$Phase, [string]$TaskId, [string]$Prompt, [bool]$DryRun = $true)
    Assert-UniqueAIConfig -Config $Config
    if ($DryRun) { return [ordered]@{ ok = $true; invoked = $false; dry_run = $true; phase = $Phase; attempts = 0 } }

    $usageInfo = Get-UsageState -TaskId $TaskId
    $usage = $usageInfo.state
    $estimatedCost = [double]$Config.limits.estimated_cost_per_invocation_usd
    if ([int]$usage.invocations -ge [int]$Config.limits.max_invocations -or
        ([double]$usage.estimated_spend_usd + $estimatedCost) -gt [double]$Config.limits.budget_usd) {
        return [ordered]@{ ok = $false; invoked = $false; dry_run = $false; phase = $Phase; failure = 'budget_exhausted'; attempts = 0 }
    }

    $ready = Test-UniqueAIProviderReady -Config $Config
    if (-not $ready.ready) { return [ordered]@{ ok = $false; invoked = $false; dry_run = $false; phase = $Phase; failure = $ready.reason; attempts = 0 } }

    $maxAttempts = 1 + [int]$Config.limits.max_retries
    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = [string]$Config.provider.executable
        $startInfo.Arguments = ConvertTo-ProcessArguments -Arguments @($Config.provider.arguments)
        $startInfo.UseShellExecute = $false
        $startInfo.RedirectStandardInput = $true
        $startInfo.RedirectStandardOutput = $true
        $startInfo.RedirectStandardError = $true
        $startInfo.CreateNoWindow = $true
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $startInfo
        try {
            [void]$process.Start()
            $process.StandardInput.Write($Prompt)
            $process.StandardInput.Close()
            $finished = $process.WaitForExit(([int]$Config.limits.timeout_seconds * 1000))
            if (-not $finished) {
                try { $process.Kill() } catch {}
                $failure = 'timeout'
                $exitCode = -1
                $stdout = ''
                $stderr = ''
            } else {
                $stdout = $process.StandardOutput.ReadToEnd()
                $stderr = $process.StandardError.ReadToEnd()
                $exitCode = $process.ExitCode
                $failure = if ($exitCode -eq 0) { $null } else { 'provider_failed' }
            }
        } catch {
            $failure = 'provider_start_failed'
            $exitCode = -1
            $stdout = ''
            $stderr = $_.Exception.Message
        } finally { if ($null -ne $process) { $process.Dispose() } }

        $usage.invocations = [int]$usage.invocations + 1
        $usage.estimated_spend_usd = [math]::Round(([double]$usage.estimated_spend_usd + $estimatedCost), 4)
        Write-Utf8JsonFile -Path $usageInfo.path -Value $usage
        if ($exitCode -eq 0) {
            return [ordered]@{ ok = $true; invoked = $true; dry_run = $false; phase = $Phase; attempts = $attempt; exit_code = 0; output = $stdout; provider_identity = (Get-ProviderIdentity -Config $Config) }
        }
        if ($attempt -eq $maxAttempts) {
            return [ordered]@{ ok = $false; invoked = $true; dry_run = $false; phase = $Phase; attempts = $attempt; exit_code = $exitCode; failure = $failure; error = $stderr }
        }
    }
}
