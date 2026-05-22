$ErrorActionPreference = "Stop"

Write-Output "SpecBridge schema validation started."

$failed = $false

$requiredSchemas = @(
  ".specbridge/schemas/audit-packet.schema.json",
  ".specbridge/schemas/autonomy-metrics.schema.json",
  ".specbridge/schemas/chatgpt-audit.schema.json",
  ".specbridge/schemas/claude-review-output.schema.json",
  ".specbridge/schemas/codex-review-output.schema.json",
  ".specbridge/schemas/executor-packet.schema.json",
  ".specbridge/schemas/final-report.schema.json",
  ".specbridge/schemas/runtime-execution.schema.json",
  ".specbridge/schemas/runtime-launch.schema.json",
  ".specbridge/schemas/runtime-result.schema.json",
  ".specbridge/schemas/runtime-run.schema.json",
  ".specbridge/schemas/runtime-summary.schema.json"
)

foreach ($schema in $requiredSchemas) {
  if (-not (Test-Path $schema)) {
    Write-Output "FAIL missing schema file: $schema"
    $failed = $true
    continue
  }

  try {
    $raw = Get-Content $schema -Raw
    $parsed = $raw | ConvertFrom-Json

    if (-not $parsed.'$schema') {
      Write-Output "FAIL schema missing `$schema field: $schema"
      $failed = $true
    }

    if (-not $parsed.title) {
      Write-Output "FAIL schema missing title: $schema"
      $failed = $true
    }

    if ($parsed.type -ne "object") {
      Write-Output "FAIL schema root type must be object: $schema"
      $failed = $true
    }

    if (-not $parsed.required) {
      Write-Output "FAIL schema missing required array: $schema"
      $failed = $true
    }

    if (-not $parsed.properties) {
      Write-Output "FAIL schema missing properties object: $schema"
      $failed = $true
    }
  }
  catch {
    Write-Output "FAIL invalid JSON schema file: $schema error=$($_.Exception.Message)"
    $failed = $true
  }
}

if ($failed) {
  Write-Output "SpecBridge schema validation failed."
  exit 1
}

Write-Output "SpecBridge schema validation passed."
exit 0
