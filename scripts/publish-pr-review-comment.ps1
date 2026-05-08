param(
  [string] $CommentPath = ".specbridge/generated-review-reports/generated-pr-review-comment.md"
)

$ErrorActionPreference = "Stop"

Write-Output "SpecBridge PR review comment publishing started."

function Invoke-GhOrFail {
  param(
    [string[]] $Arguments,
    [string] $FailureMessage
  )

  & gh @Arguments

  if ($LASTEXITCODE -ne 0) {
    Write-Output "FAIL $FailureMessage"
    exit $LASTEXITCODE
  }
}

if (-not (Test-Path $CommentPath)) {
  Write-Output "FAIL missing rendered PR review comment: $CommentPath"
  exit 1
}

if (-not $env:GITHUB_REPOSITORY) {
  Write-Output "FAIL missing GITHUB_REPOSITORY environment variable."
  exit 1
}

if (-not $env:GITHUB_EVENT_PATH -or -not (Test-Path $env:GITHUB_EVENT_PATH)) {
  Write-Output "FAIL missing GITHUB_EVENT_PATH."
  exit 1
}

if (-not $env:GH_TOKEN) {
  Write-Output "FAIL missing GH_TOKEN environment variable."
  exit 1
}

$eventPayload = Get-Content $env:GITHUB_EVENT_PATH -Raw | ConvertFrom-Json
$prNumber = $eventPayload.pull_request.number

if (-not $prNumber) {
  Write-Output "FAIL unable to determine pull request number from GitHub event payload."
  exit 1
}

$marker = "<!-- specbridge-pr-review-report -->"
$body = Get-Content $CommentPath -Raw
$repo = $env:GITHUB_REPOSITORY

$commentsRaw = & gh api "repos/$repo/issues/$prNumber/comments"

if ($LASTEXITCODE -ne 0) {
  Write-Output "FAIL unable to list PR comments."
  exit $LASTEXITCODE
}

$comments = $commentsRaw | ConvertFrom-Json
$existingComment = $null

foreach ($comment in @($comments)) {
  if ($comment.body -and $comment.body.Contains($marker)) {
    $existingComment = $comment
    break
  }
}

$tempPayload = New-TemporaryFile

try {
  @{ body = $body } |
    ConvertTo-Json -Depth 10 |
    Set-Content -Path $tempPayload.FullName -Encoding UTF8

  if ($existingComment) {
    Write-Output "Updating existing SpecBridge PR review comment: $($existingComment.id)"

    Invoke-GhOrFail `
      -Arguments @(
        "api",
        "--method", "PATCH",
        "repos/$repo/issues/comments/$($existingComment.id)",
        "--input", $tempPayload.FullName
      ) `
      -FailureMessage "unable to update SpecBridge PR review comment."
  } else {
    Write-Output "Creating new SpecBridge PR review comment on PR #$prNumber"

    Invoke-GhOrFail `
      -Arguments @(
        "api",
        "--method", "POST",
        "repos/$repo/issues/$prNumber/comments",
        "--input", $tempPayload.FullName
      ) `
      -FailureMessage "unable to create SpecBridge PR review comment."
  }
} finally {
  Remove-Item -Force $tempPayload.FullName -ErrorAction SilentlyContinue
}

Write-Output "SpecBridge PR review comment publishing passed."
exit 0
