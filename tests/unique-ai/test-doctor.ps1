# tests/unique-ai/test-doctor.ps1
# Tests for the doctor command. Exits 0 if all pass, 1 if any fail.
param([string]$RepoRoot = '')

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
}

$scriptPath = Join-Path $RepoRoot 'scripts\unique-ai.ps1'

$passed = 0
$failed = 0

function Assert-Condition {
    param([string]$Name, [bool]$Condition, [string]$Detail = '')
    if ($Condition) {
        Write-Host "  PASS: $Name"
        $script:passed++
    } else {
        Write-Host "  FAIL: $Name$(if ($Detail) { ": $Detail" })"
        $script:failed++
    }
}

Write-Host "=== test-doctor ==="

# Test 1: doctor exits 0
$output = & powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath doctor 2>&1
$exitCode = $LASTEXITCODE
Assert-Condition 'doctor exits 0' ($exitCode -eq 0)

# Test 2: doctor output is valid JSON
$json = $null
try { $json = $output | ConvertFrom-Json } catch {}
Assert-Condition 'doctor output is valid JSON' ($null -ne $json)

# Test 3: ok field is true
Assert-Condition 'doctor ok=true' ($null -ne $json -and $json.ok -eq $true)

# Test 4: command field is "doctor"
Assert-Condition 'doctor command field' ($null -ne $json -and $json.command -eq 'doctor')

# Test 5: timestamp present
Assert-Condition 'doctor has timestamp' ($null -ne $json -and -not [string]::IsNullOrWhiteSpace($json.timestamp))

# Test 6: config_status present
Assert-Condition 'doctor has config_status' ($null -ne $json -and $null -ne $json.config_status)

# Test 7: provider_ready present
Assert-Condition 'doctor has provider_ready' ($null -ne $json -and $null -ne $json.provider_ready)

# Test 8: policy present
Assert-Condition 'doctor has policy' ($null -ne $json -and -not [string]::IsNullOrWhiteSpace($json.policy))

# Test 9: review_label is correct
Assert-Condition 'doctor review_label=fresh_session_self_review' (
    $null -ne $json -and $json.review_label -eq 'fresh_session_self_review'
)

# Test 10: config_status should be "ok" since config.json exists
Assert-Condition 'doctor config_status=ok' ($null -ne $json -and $json.config_status -eq 'ok')

Write-Host ""
Write-Host "test-doctor: $passed passed, $failed failed"

exit $(if ($failed -gt 0) { 1 } else { 0 })
