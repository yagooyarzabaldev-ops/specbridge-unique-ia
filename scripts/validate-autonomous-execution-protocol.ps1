$ErrorActionPreference = "Stop"

Write-Output "SpecBridge autonomous execution protocol validation started."

$requiredFiles = @(
  ".specbridge/context/chatgpt-developer-role.md",
  ".specbridge/context/claude-code-executor-role.md",
  ".specbridge/context/autonomy-policy.md",
  ".specbridge/context/escalation-policy.md",
  ".specbridge/context/audit-packet-standard.md",
  ".claude/commands/specbridge-execute.md",
  ".claude/commands/specbridge-escalate.md",
  ".claude/rules/specbridge-autonomous-execution.md",
  "docs/specbridge-chatgpt-governed-execution.md"
)

$requiredRegexPatterns = @(
  "ChatGPT\s+governs",
  "Claude\s+Code\s+executes",
  "autonomous_within_contract",
  "chatgpt_approval_required",
  "human_approval_required",
  "blocked",
  "escalation",
  "audit\s+packet",
  "Do\s+not\s+push",
  "main",
  "Do\s+not\s+merge"
)

$forbiddenRegexPatterns = @(
  "Claude\s+Code\s+may\s+push\s+to\s+main",
  "Claude\s+Code\s+may\s+merge",
  "autonomous\s+merge\s+allowed",
  "push\s+directly\s+to\s+main"
)

$failed = $false

foreach ($file in $requiredFiles) {
  if (-not (Test-Path $file)) {
    Write-Output "FAIL missing autonomous execution protocol file: $file"
    $failed = $true
    continue
  }

  $content = Get-Content $file -Raw

  if ([string]::IsNullOrWhiteSpace($content)) {
    Write-Output "FAIL empty autonomous execution protocol file: $file"
    $failed = $true
  }
}

$combinedContent = ""

foreach ($file in $requiredFiles) {
  if (Test-Path $file) {
    $combinedContent += "`n"
    $combinedContent += Get-Content $file -Raw
  }
}

foreach ($pattern in $requiredRegexPatterns) {
  if ($combinedContent -notmatch $pattern) {
    Write-Output "FAIL missing required autonomous execution pattern: $pattern"
    $failed = $true
  }
}

foreach ($pattern in $forbiddenRegexPatterns) {
  if ($combinedContent -match $pattern) {
    Write-Output "FAIL forbidden autonomous execution pattern detected: $pattern"
    $failed = $true
  }
}

if ($failed) {
  Write-Output "SpecBridge autonomous execution protocol validation failed."
  exit 1
}

Write-Output "SpecBridge autonomous execution protocol validation passed."
exit 0
