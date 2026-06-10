param(
  [Parameter(Position = 0)]
  [ValidateSet("status", "validate", "create-contract", "create-report", "audit-packet", "detect-conflicts", "decompose-task", "prepare-executors", "prepare-runtime-launch", "preflight-runtime-launches", "execute-runtime-launch", "run-runtime-launch", "record-runtime-result", "summarize-runtime", "summarize-autonomy-metrics", "standard-loop-status", "standard-loop-orchestrate", "issue-to-merge-plan", "issue-to-merge-github", "specbridge-intake", "specbridge-doctor", "specbridge-orchestrate", "specbridge-handoff", "specbridge-review-report", "specbridge-next-task", "generate-dashboard", "generate-studio-dashboard", "lifecycle-guard", "quickstart", "v5-pilot-status", "v5-live-status", "v5-autonomy-status", "v5-serious-pilot-status", "runtime-capability-status", "bounded-live-pilot-status", "plan-executor-branches", "record-github-evidence", "coordinate-executors", "review-gate")]
  [string] $Command = "status",

  [string] $TaskId = "",
  [string] $Agent = "",
  [string] $Verdict = "",
  [string] $Title = "",
  [string] $Goal = "",
  [string] $RelatedIssue = "",
  [string] $OutputPath = "",
  [string] $InputPath = "",
  [string] $ContractPath = "",
  [string] $ReportPath = "",
  [string] $OutputDirectory = "",
  [string] $OutputFileName = "",
  [string] $EvidencePath = "",
  [string] $CiStatus = "not_collected",
  [string] $Summary = "",
  [string[]] $ChangedFile = @(),
  [string[]] $Validation = @(),
  [string[]] $RequiredSlice = @(),
  [string] $PolicyResult = "",
  [string] $RiskResult = "",
  [string] $CompletionStatus = "draft",
  [string] $Profile = "standard",
  [string] $BranchPrefix = "claude",
  [string[]] $AllowedTool = @("Read", "Write"),
  [ValidateSet("acceptEdits", "auto", "default", "dontAsk", "plan")]
  [string] $PermissionMode = "acceptEdits",
  [string] $MaxBudgetUsd = "2.00",
  [int] $RuntimeExitCode = 0,
  [int] $TimeoutSeconds = 300,
  [string[]] $WrittenFile = @(),
  [ValidateSet("simulation", "github")]
  [string] $EvidenceMode = "simulation",
  [ValidateSet("dry_run", "apply")]
  [string] $MutationMode = "dry_run",
  [ValidateSet("issue_create", "pr_open", "ci_wait", "merge", "issue_close", "post_merge_memory")]
  [string[]] $GithubOperation = @(),
  [string] $RepositoryUrl = "https://github.com/yagooyarzabaldev-ops/specbridge",
  [string] $BaseBranch = "main",
  [switch] $IncludeLatestArtifacts,
  [switch] $DryRun,
  [switch] $ConfirmGithubMutation,
  [switch] $Force,
  [switch] $FixPlan,
  [ValidateSet("json", "human", "both")]
  [string] $OutputFormat = "json",
  [switch] $Online,
  [switch] $Offline,
  [switch] $RequireOnline
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

foreach ($specbridgeLib in @(
  "common.ps1",
  "status.ps1",
  "contracts.ps1",
  "runtime.ps1",
  "github-ops.ps1",
  "intake-doctor.ps1",
  "dashboards.ps1"
)) {
  . (Join-Path $PSScriptRoot "lib/$specbridgeLib")
}

switch ($Command) {
  "status" { Invoke-StatusCommand }
  "validate" { Invoke-ValidateCommand }
  "create-contract" { Invoke-CreateContractCommand }
  "create-report" { Invoke-CreateReportCommand }
  "audit-packet" { Invoke-AuditPacketCommand }
  "detect-conflicts" { Invoke-DetectConflictsCommand }
  "decompose-task" { Invoke-DecomposeTaskCommand }
  "prepare-executors" { Invoke-PrepareExecutorsCommand }
  "prepare-runtime-launch" { Invoke-PrepareRuntimeLaunchCommand }
  "preflight-runtime-launches" { Invoke-PreflightRuntimeLaunchesCommand }
  "execute-runtime-launch" { Invoke-ExecuteRuntimeLaunchCommand }
  "run-runtime-launch" { Invoke-RunRuntimeLaunchCommand }
  "record-runtime-result" { Invoke-RecordRuntimeResultCommand }
  "summarize-runtime" { Invoke-SummarizeRuntimeCommand }
  "summarize-autonomy-metrics" { Invoke-SummarizeAutonomyMetricsCommand }
  "standard-loop-status" { Invoke-StandardLoopStatusCommand }
  "standard-loop-orchestrate" { Invoke-StandardLoopOrchestrateCommand }
  "issue-to-merge-plan" { Invoke-IssueToMergePlanCommand }
  "issue-to-merge-github" { Invoke-IssueToMergeGithubCommand }
  "specbridge-intake" { Invoke-SpecbridgeIntakeCommand }
  "specbridge-doctor" { Invoke-SpecbridgeDoctorCommand }
  "specbridge-orchestrate" { Invoke-SpecbridgeOrchestrateCommand }
  "specbridge-handoff" { Invoke-SpecbridgeHandoffCommand }
  "specbridge-review-report" { Invoke-SpecbridgeReviewReportCommand }
  "specbridge-next-task" { Invoke-SpecbridgeNextTaskCommand }
  "generate-dashboard" { Invoke-GenerateDashboardCommand }
  "generate-studio-dashboard" { Invoke-GenerateStudioDashboardCommand }
  "lifecycle-guard" { Invoke-LifecycleGuardCommand }
  "quickstart" { Invoke-QuickstartCommand }
  "v5-pilot-status" { Invoke-V5PilotStatusCommand }
  "v5-live-status" { Invoke-V5LiveStatusCommand }
  "v5-autonomy-status" { Invoke-V5AutonomyStatusCommand }
  "v5-serious-pilot-status" { Invoke-V5SeriousPilotStatusCommand }
  "runtime-capability-status" { Invoke-RuntimeCapabilityStatusCommand }
  "bounded-live-pilot-status" { Invoke-BoundedLivePilotStatusCommand }
  "plan-executor-branches" { Invoke-PlanExecutorBranchesCommand }
  "record-github-evidence" { Invoke-RecordGithubEvidenceCommand }
  "coordinate-executors" { Invoke-CoordinateExecutorsCommand }
  "review-gate" { Invoke-ReviewGateCommand }
  default { Fail "Unsupported command: $Command" }
}
