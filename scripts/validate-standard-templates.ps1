$ErrorActionPreference = "Stop"

Write-Output "SpecBridge standard template validation started."

$failed = $false

$templateFiles = @(
  "templates/specbridge/execution-contract.template.md",
  "templates/specbridge/scope-manifest.template.json",
  "templates/specbridge/executor-handoff.template.json",
  "templates/specbridge/runtime-launch.template.json",
  "templates/specbridge/final-report.template.json",
  "templates/specbridge/audit-packet.template.json",
  "templates/specbridge/chatgpt-audit.template.json"
)

function Write-Failure {
  param(
    [string] $Message
  )

  Write-Output "FAIL $Message"
  $script:failed = $true
}

foreach ($template in $templateFiles) {
  if (-not (Test-Path -LiteralPath $template -PathType Leaf)) {
    Write-Failure "missing standard template: $template"
    continue
  }

  $raw = Get-Content -LiteralPath $template -Raw

  if ([string]::IsNullOrWhiteSpace($raw)) {
    Write-Failure "standard template must not be empty: $template"
  }

  if ($raw -notmatch "{{TASK_ID}}") {
    Write-Failure "standard template must include {{TASK_ID}} placeholder: $template"
  }

  if ($template -like "*.json") {
    $jsonProbe = $raw -replace "\{\{[A-Z0-9_]+\}\}", "PLACEHOLDER"

    try {
      [void] ($jsonProbe | ConvertFrom-Json)
    }
    catch {
      Write-Failure "JSON standard template must remain parseable after placeholder substitution: $template"
    }
  }
}

if ($failed) {
  Write-Output "SpecBridge standard template validation failed."
  exit 1
}

Write-Output "SpecBridge standard template validation passed."
exit 0
