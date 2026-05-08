$ErrorActionPreference = "Stop"

Write-Output "SpecBridge Claude review workflow validation started."

$workflowPath = ".github/workflows/claude-review-non-blocking.yml"
$failed = $false

if (-not (Test-Path $workflowPath)) {
  Write-Output "FAIL missing Claude review workflow: $workflowPath"
  exit 1
}

$content = Get-Content $workflowPath -Raw

$requiredPatterns = @(
  "name:\s+Claude Review Non Blocking",
  "pull_request:",
  "contents:\s+read",
  "pull-requests:\s+write",
  "issues:\s+write",
  "continue-on-error:\s+true",
  "ANTHROPIC_API_KEY",
  "anthropics/claude-code-action@v1",
  "github_token:\s+\$\{\{\s*github\.token\s*\}\}",
  "--max-turns\s+3"
)

foreach ($pattern in $requiredPatterns) {
  if ($content -notmatch $pattern) {
    Write-Output "FAIL missing required Claude review workflow pattern: $pattern"
    $failed = $true
  }
}

$blockedPatterns = @(
  "contents:\s+write",
  "git\s+push",
  "gh\s+pr\s+merge",
  "gh\s+pr\s+create",
  "gh\s+api\s+repos/.+/merges",
  "docker\s+push",
  "kubectl\s+",
  "terraform\s+apply",
  "render\s+deploy",
  "vercel\s+--prod",
  "aws\s+.*deploy",
  "gcloud\s+.*deploy",
  "az\s+.*deployment"
)

foreach ($pattern in $blockedPatterns) {
  if ($content -match $pattern) {
    Write-Output "FAIL blocked Claude review workflow pattern present: $pattern"
    $failed = $true
  }
}

if ($content -match "secrets\." -and $content -notmatch "secrets\.ANTHROPIC_API_KEY") {
  Write-Output "FAIL Claude review workflow references unapproved secret."
  $failed = $true
}

if ($failed) {
  Write-Output "SpecBridge Claude review workflow validation failed."
  exit 1
}

Write-Output "SpecBridge Claude review workflow validation passed."
exit 0
