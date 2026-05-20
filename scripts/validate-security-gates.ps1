$ErrorActionPreference = "Stop"

Write-Output "SpecBridge security gate validation started."

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$failed = $false

$protectedPathPatterns = @(
  "^\.env$",
  "^\.env\.",
  "(^|/)secrets(/|$)",
  "\.(pem|key)$",
  "(^|/)[^/]*secret[^/]*$",
  "^infra/prod(/|$)"
)

$authSensitivePathPatterns = @(
  "(^|/)(auth|authentication|login|oauth|jwt|session)(/|$)",
  "(^|/)(auth|authentication|login|oauth|jwt|session)[-_.][^/]*$"
)

$authorizationSensitivePathPatterns = @(
  "(^|/)(authorization|rbac|access-control|permissions|policy-engine)(/|$)",
  "(^|/)(authorization|rbac|access-control|permissions|policy-engine)[-_.][^/]*$"
)

$productionConfigurationPathPatterns = @(
  "^infra/prod(/|$)",
  "(^|/)(prod|production)(/|$)",
  "(^|/)(prod|production)[-_.][^/]*$",
  "(^|/)docker-compose\.prod\.ya?ml$",
  "(^|/)k8s/prod(/|$)",
  "(^|/)helm/prod(/|$)"
)

$dependencyPathPatterns = @(
  "(^|/)package\.json$",
  "(^|/)package-lock\.json$",
  "(^|/)pnpm-lock\.yaml$",
  "(^|/)yarn\.lock$",
  "(^|/)requirements\.txt$",
  "(^|/)pyproject\.toml$",
  "(^|/)poetry\.lock$",
  "(^|/)Cargo\.toml$",
  "(^|/)Cargo\.lock$",
  "(^|/)go\.mod$",
  "(^|/)go\.sum$",
  "(^|/)pom\.xml$",
  "(^|/)build\.gradle$",
  "(^|/)build\.gradle\.kts$",
  "\.(csproj|fsproj|vbproj)$"
)

$secretLikeContentPatterns = @(
  @{
    Pattern = "-----BEGIN (RSA |EC |OPENSSH |DSA |)?PRIVATE KEY-----"
    Detail = "private key material"
  },
  @{
    Pattern = "AKIA[0-9A-Z]{16}"
    Detail = "AWS access key shape"
  },
  @{
    Pattern = "gh[pousr]_[A-Za-z0-9_]{36,}"
    Detail = "GitHub token shape"
  },
  @{
    Pattern = "xox[baprs]-[A-Za-z0-9-]{20,}"
    Detail = "Slack token shape"
  },
  @{
    Pattern = "sk-[A-Za-z0-9]{32,}"
    Detail = "API key shape"
  },
  @{
    Pattern = "sk-ant-[A-Za-z0-9_-]{20,}"
    Detail = "Anthropic key shape"
  },
  @{
    Pattern = "(?i)\b(password|passwd|api[_-]?key|secret|token|client[_-]?secret)\b\s*[:=]\s*[""'][^""'\r\n]{12,}[""']"
    Detail = "credential assignment shape"
  }
)

$unsafeShellCommandPatterns = @(
  @{
    Pattern = "rm\s+-rf\s+(/|\*|~|`$HOME|%USERPROFILE%)"
    Detail = "destructive recursive delete"
  },
  @{
    Pattern = "sudo\s+"
    Detail = "privileged shell command"
  },
  @{
    Pattern = "curl\s+[^|]*\|\s*(bash|sh|powershell|pwsh)"
    Detail = "remote script execution through curl"
  },
  @{
    Pattern = "wget\s+[^|]*\|\s*(bash|sh|powershell|pwsh)"
    Detail = "remote script execution through wget"
  },
  @{
    Pattern = "chmod\s+-R\s+777"
    Detail = "recursive world-writable permission change"
  },
  @{
    Pattern = "docker\s+system\s+prune"
    Detail = "destructive Docker cleanup"
  },
  @{
    Pattern = ("Invoke" + "-Expression")
    Detail = "PowerShell expression evaluation"
  },
  @{
    Pattern = "\b" + ("i" + "ex") + "\b\s*\("
    Detail = "PowerShell expression alias"
  },
  @{
    Pattern = "Set-ExecutionPolicy\s+Unrestricted"
    Detail = "unrestricted PowerShell execution policy"
  }
)

$ciPermissionEscalationPatterns = @(
  @{
    Pattern = "(?m)^\s*permissions:\s*write\s*$"
    Detail = "workflow grants write permissions globally"
  },
  @{
    Pattern = "(?m)^\s*(contents|id-token|actions|pull-requests|checks|deployments):\s*write\s*$"
    Detail = "workflow grants write permission to a sensitive scope"
  }
)

function Write-SecurityFinding {
  param(
    [string] $Category,
    [string] $Path,
    [string] $Detail
  )

  Write-Output "FAIL security category=$Category path=$Path detail=$Detail"
  $script:failed = $true
}

function Invoke-GitLines {
  param(
    [string[]] $Arguments
  )

  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"

  try {
    $output = & git @Arguments 2>$null

    if ($LASTEXITCODE -ne 0) {
      return @()
    }

    return @($output | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
  }
  finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }
}

function Normalize-RepoPath {
  param(
    [string] $Path
  )

  $normalizedPath = $Path.Trim().Replace("\", "/")

  while ($normalizedPath.StartsWith("./")) {
    $normalizedPath = $normalizedPath.Substring(2)
  }

  return $normalizedPath
}

function Get-ChangedFiles {
  $files = @()

  if ($env:GITHUB_BASE_REF) {
    [void] (Invoke-GitLines -Arguments @("fetch", "origin", $env:GITHUB_BASE_REF, "--depth=1"))
    $files += Invoke-GitLines -Arguments @("diff", "--name-only", "origin/$($env:GITHUB_BASE_REF)...HEAD")
  }

  $files += Invoke-GitLines -Arguments @("diff", "--name-only")
  $files += Invoke-GitLines -Arguments @("diff", "--name-only", "--cached")
  $files += Invoke-GitLines -Arguments @("diff", "--name-only", "HEAD~1..HEAD")

  return @(
    $files |
      Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
      ForEach-Object { Normalize-RepoPath -Path $_ } |
      Sort-Object -Unique
  )
}

function Test-PathCategory {
  param(
    [string] $Path,
    [string] $Category,
    [string[]] $Patterns,
    [string] $Detail
  )

  foreach ($pattern in $Patterns) {
    if ($Path -match $pattern) {
      Write-SecurityFinding -Category $Category -Path $Path -Detail $Detail
      return
    }
  }
}

function Get-FileText {
  param(
    [string] $Path
  )

  $localPath = Join-Path $repoRoot ($Path.Replace("/", [System.IO.Path]::DirectorySeparatorChar))

  if (-not (Test-Path -LiteralPath $localPath -PathType Leaf)) {
    return $null
  }

  try {
    $bytes = [System.IO.File]::ReadAllBytes($localPath)
  }
  catch {
    return $null
  }

  if ($bytes -contains 0) {
    return $null
  }

  return [System.Text.Encoding]::UTF8.GetString($bytes)
}

function Test-ContentPatterns {
  param(
    [string] $Path,
    [string] $Content,
    [string] $Category,
    [object[]] $Patterns
  )

  foreach ($entry in $Patterns) {
    if ($Content -match $entry.Pattern) {
      Write-SecurityFinding -Category $Category -Path $Path -Detail $entry.Detail
      return
    }
  }
}

$changedFiles = Get-ChangedFiles

if ($changedFiles.Count -eq 0) {
  Write-Output "No changed files detected. Security gate passes."
  exit 0
}

Write-Output "Changed files:"
foreach ($changedFile in $changedFiles) {
  Write-Output "- $changedFile"
}

foreach ($changedFile in $changedFiles) {
  Test-PathCategory `
    -Path $changedFile `
    -Category "protected_path_change" `
    -Patterns $protectedPathPatterns `
    -Detail "protected path changed"

  Test-PathCategory `
    -Path $changedFile `
    -Category "auth_sensitive_file" `
    -Patterns $authSensitivePathPatterns `
    -Detail "authentication-sensitive path changed"

  Test-PathCategory `
    -Path $changedFile `
    -Category "authorization_sensitive_file" `
    -Patterns $authorizationSensitivePathPatterns `
    -Detail "authorization-sensitive path changed"

  Test-PathCategory `
    -Path $changedFile `
    -Category "production_configuration" `
    -Patterns $productionConfigurationPathPatterns `
    -Detail "production configuration path changed"

  Test-PathCategory `
    -Path $changedFile `
    -Category "dependency_addition" `
    -Patterns $dependencyPathPatterns `
    -Detail "dependency manifest or lockfile changed"

  $content = Get-FileText -Path $changedFile

  if ($null -eq $content) {
    continue
  }

  Test-ContentPatterns `
    -Path $changedFile `
    -Content $content `
    -Category "secret_like_content" `
    -Patterns $secretLikeContentPatterns

  Test-ContentPatterns `
    -Path $changedFile `
    -Content $content `
    -Category "unsafe_shell_command" `
    -Patterns $unsafeShellCommandPatterns

  if ($changedFile -match "^\.github/workflows/.+\.ya?ml$") {
    Test-ContentPatterns `
      -Path $changedFile `
      -Content $content `
      -Category "ci_cd_permission_escalation" `
      -Patterns $ciPermissionEscalationPatterns
  }
}

if ($failed) {
  Write-Output "SpecBridge security gate validation failed."
  exit 1
}

Write-Output "SpecBridge security gate validation passed."
exit 0
