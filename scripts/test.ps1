<#
.SYNOPSIS
  SpecBridge Unique IA test runner. Executes all tests/unique-ai/ test scripts.
.DESCRIPTION
  PowerShell 5.1 compatible. Exits 0 if all tests pass, 1 if any fail.
  Does not call the AI provider. Runs deterministic, no-network tests only.
#>
param(
    [string]$TestFilter = '',
    [switch]$Verbose
)

$ErrorActionPreference = 'Stop'

$REPO_ROOT  = Split-Path $PSScriptRoot -Parent
$TESTS_DIR  = Join-Path $REPO_ROOT 'tests\unique-ai'

Write-Host ''
Write-Host 'SpecBridge Unique IA - Test Suite'
Write-Host '=================================='
Write-Host "Repo root : $REPO_ROOT"
Write-Host "Tests dir : $TESTS_DIR"
Write-Host ''

if (-not (Test-Path $TESTS_DIR)) {
    Write-Host "ERROR: tests directory not found: $TESTS_DIR"
    exit 1
}

$testFiles = @(Get-ChildItem -Path $TESTS_DIR -Filter 'test-*.ps1' -ErrorAction SilentlyContinue |
    Sort-Object Name)

if ($testFiles.Count -eq 0) {
    Write-Host 'No test files found.'
    exit 1
}

$totalPassed = 0
$totalFailed = 0
$fileResults = @()

foreach ($testFile in $testFiles) {
    if ($TestFilter -and $testFile.Name -notlike "*$TestFilter*") { continue }

    Write-Host "Running: $($testFile.Name)"
    $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $testFile.FullName `
        -RepoRoot $REPO_ROOT 2>&1
    $exitCode = $LASTEXITCODE

    if ($Verbose) { $output | ForEach-Object { Write-Host "  $_" } }
    else          { $output | ForEach-Object { Write-Host "  $_" } }

    # Parse pass/fail count from last summary line
    $summaryLine = @($output | Where-Object { $_ -match '(\d+) passed, (\d+) failed' })
    $filePassed = 0
    $fileFailed = 0
    if ($summaryLine.Count -gt 0) {
        $m = [regex]::Match($summaryLine[-1], '(\d+) passed, (\d+) failed')
        if ($m.Success) {
            $filePassed = [int]$m.Groups[1].Value
            $fileFailed = [int]$m.Groups[2].Value
        }
    } elseif ($exitCode -ne 0) {
        $fileFailed = 1
    }

    $totalPassed += $filePassed
    $totalFailed += $fileFailed

    $fileResults += [ordered]@{
        file   = $testFile.Name
        passed = $filePassed
        failed = $fileFailed
        exit   = $exitCode
    }

    Write-Host ''
}

Write-Host '=================================='
Write-Host "Results: $totalPassed passed, $totalFailed failed"
Write-Host ''

foreach ($r in $fileResults) {
    $status = if ($r.failed -eq 0) { 'PASS' } else { 'FAIL' }
    Write-Host "  [$status] $($r.file) ($($r.passed) passed, $($r.failed) failed)"
}

Write-Host ''

if ($totalFailed -gt 0) {
    Write-Host "FAIL: $totalFailed test(s) failed."
    exit 1
} else {
    Write-Host 'PASS: All tests passed.'
    exit 0
}
