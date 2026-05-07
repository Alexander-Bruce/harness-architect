[CmdletBinding()]
param(
    [ValidateSet("commands", "scaffold", "docs-check", "audit")]
    [string]$Command = "commands",

    [string]$RepoPath = (Get-Location).Path,

    [switch]$Force
)

$ErrorActionPreference = "Stop"

function Resolve-RepoRoot {
    param([string]$Path)

    $current = Resolve-Path -LiteralPath $Path
    while ($null -ne $current) {
        $markers = @(".git", "pom.xml", "package.json", "pyproject.toml", "go.mod", "Cargo.toml")
        foreach ($marker in $markers) {
            if (Test-Path -LiteralPath (Join-Path $current.Path $marker)) {
                return $current.Path
            }
        }
        $parent = Split-Path -Parent $current.Path
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $current.Path) {
            break
        }
        $current = Resolve-Path -LiteralPath $parent
    }

    return (Resolve-Path -LiteralPath $Path).Path
}

function Get-StackInfo {
    param([string]$Root)

    $items = New-Object System.Collections.Generic.List[string]
    $commands = New-Object System.Collections.Generic.List[string]

    if (Test-Path -LiteralPath (Join-Path $Root "pom.xml")) {
        $items.Add("Java/Maven")
        $commands.Add("mvn test")
    }
    if ((Test-Path -LiteralPath (Join-Path $Root "build.gradle")) -or (Test-Path -LiteralPath (Join-Path $Root "build.gradle.kts"))) {
        $items.Add("Gradle")
        if (Test-Path -LiteralPath (Join-Path $Root "gradlew")) {
            $commands.Add(".\gradlew test")
        } else {
            $commands.Add("gradle test")
        }
    }
    if (Test-Path -LiteralPath (Join-Path $Root "package.json")) {
        $items.Add("Node/package.json")
        $commands.Add("npm test")
    }
    if ((Test-Path -LiteralPath (Join-Path $Root "pyproject.toml")) -or (Test-Path -LiteralPath (Join-Path $Root "requirements.txt"))) {
        $items.Add("Python")
        $commands.Add("pytest")
    }
    if ((Get-ChildItem -LiteralPath $Root -File -Filter "*.sln" -ErrorAction SilentlyContinue) -or (Get-ChildItem -LiteralPath $Root -Recurse -File -Filter "*.csproj" -ErrorAction SilentlyContinue | Select-Object -First 1)) {
        $items.Add(".NET")
        $commands.Add("dotnet test")
    }
    if (Test-Path -LiteralPath (Join-Path $Root "Cargo.toml")) {
        $items.Add("Rust/Cargo")
        $commands.Add("cargo test")
    }
    if (Test-Path -LiteralPath (Join-Path $Root "go.mod")) {
        $items.Add("Go")
        $commands.Add("go test ./...")
    }

    if ($items.Count -eq 0) {
        $items.Add("Unknown")
    }
    if ($commands.Count -eq 0) {
        $commands.Add("<fill project test command>")
    }

    return [PSCustomObject]@{
        Stack = ($items -join ", ")
        VerifyCommands = ($commands | Select-Object -Unique)
    }
}

function Write-TextFile {
    param(
        [string]$Path,
        [string]$Content
    )

    if ((Test-Path -LiteralPath $Path) -and -not $Force) {
        Write-Host "keep existing: $Path"
        return
    }

    $dir = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
    Write-Host "wrote: $Path"
}

function Show-Commands {
    Write-Host "Harness Architect commands"
    Write-Host ""
    Write-Host "Skill prompts:"
    Write-Host ' - Use $harness-architect to create harness architecture docs for this project.'
    Write-Host ' - Use $harness-architect as the orchestrator and coordinate executor/evaluator agents for this task.'
    Write-Host ' - Use $harness-architect to plan, implement, test, and review this change.'
    Write-Host ' - Use $harness-architect to audit recurring agent mistakes and update the harness.'
    Write-Host ""
    Write-Host "Script commands:"
    Write-Host " - powershell -ExecutionPolicy Bypass -File scripts/harness-architect.ps1 -Command scaffold -RepoPath <repo>"
    Write-Host " - powershell -ExecutionPolicy Bypass -File scripts/harness-architect.ps1 -Command docs-check -RepoPath <repo>"
    Write-Host " - powershell -ExecutionPolicy Bypass -File scripts/harness-architect.ps1 -Command audit -RepoPath <repo>"
}

function Get-AgentsMd {
    param([string]$Stack, [string[]]$VerifyCommands)

    $verifyList = ($VerifyCommands | ForEach-Object { "- ``$_``" }) -join "`n"
    return @"
# Agent Guide

This file is the short entry point for agents working in this repository. Keep durable detail in focused docs and scripts.

## Read First

- [ARCHITECTURE.md](ARCHITECTURE.md): system map, target boundaries, invariants, risks.
- [docs/harness/README.md](docs/harness/README.md): harness operating model.
- [docs/harness/agent-protocol.md](docs/harness/agent-protocol.md): JSONL communication protocol for orchestrator, executor, evaluator, and subagents.
- [docs/harness/quality-gates.md](docs/harness/quality-gates.md): verification and hard gates.
- [docs/harness/subagent-workflows.md](docs/harness/subagent-workflows.md): main-agent/subagent workflows.
- [docs/exec-plans/tech-debt-tracker.md](docs/exec-plans/tech-debt-tracker.md): known debt and cleanup queue.

## Project Snapshot

- Detected stack: $Stack
- Fill in entry points, core modules, external systems, generated files, and deployment commands after repo inspection.

## Working Rules

- Use research-plan-implement for multi-file, risky, unclear, security-sensitive, external-system, migration, async, billing, auth, or architecture changes.
- Do not edit build output, vendored dependencies, generated files, or IDE metadata unless the task explicitly requires it.
- Do not add hard-coded secrets, credentials, tokens, or production endpoint values.
- Keep changes narrowly scoped and preserve user edits.
- Add or update tests when changing behavior.
- Update harness docs when architecture, verification, or repeated failure patterns change.
- When coordinating multiple agents, require JSONL communication: one valid JSON object per line.

## Verification

$verifyList
- ``powershell -ExecutionPolicy Bypass -File scripts/harness-check.ps1 -Mode audit``
- ``powershell -ExecutionPolicy Bypass -File scripts/harness-check.ps1 -Mode verify``
"@
}

function Get-ArchitectureMd {
    param([string]$Stack)

    return @"
# Architecture

This document captures the current system map, target boundaries, and invariants for agentic work. It should be updated as the repository becomes clearer.

## Current System Map

- Detected stack: $Stack
- Entry points: TODO
- Core modules: TODO
- Data stores: TODO
- External systems: TODO
- Background jobs/queues: TODO
- Deployment/runtime: TODO

```mermaid
flowchart LR
    User["User or external caller"] --> Entry["Entry points"]
    Entry --> Core["Core application"]
    Core --> Data["Data/storage"]
    Core --> External["External systems"]
```

## Target Boundaries

- UI/API boundary: validate external input and shape responses.
- Domain/application boundary: own business rules and workflows.
- Infrastructure boundary: wrap databases, files, HTTP clients, SDKs, queues, and other side effects.
- Configuration boundary: keep secrets and environment-specific values outside source code when possible.
- Test boundary: isolate live external systems behind fakes/mocks unless an integration run is explicitly requested.

## Invariants

- No new hard-coded secrets.
- No live production mutations from automated tests.
- No broad refactors inside unrelated tasks.
- Generated/build output is not source of truth.
- Every behavior change needs a known verification path.

## Risks And Open Questions

Track concrete findings here or in `docs/exec-plans/tech-debt-tracker.md`.
"@
}

function Get-HarnessReadme {
    return @'
# Harness

This harness makes the repository easier for agents and humans to work in.

## Model

- Inform with concise local docs.
- Constrain with architecture boundaries and hard gates.
- Verify with runnable commands.
- Correct by turning repeated failures into tests, scripts, docs, or plans.

## Task Lifecycle

1. Research the relevant files and current behavior.
2. Synchronize executor plan and evaluator acceptance criteria before coding.
3. Approve one implementation plan and one acceptance standard.
4. Implement with a narrow write scope.
5. Evaluate mechanically against the approved criteria.
6. Harvest repeated mistakes into the harness.

## Where Knowledge Lives

- `AGENTS.md`: entry point.
- `ARCHITECTURE.md`: system map and invariants.
- `docs/harness/agent-protocol.md`: JSONL inter-agent protocol.
- `docs/harness/quality-gates.md`: checks and hard gates.
- `docs/harness/subagent-workflows.md`: delegation patterns.
- `docs/exec-plans/`: durable plans and debt.
'@
}

function Get-AgentProtocol {
    return @'
# Agent Protocol

All inter-agent communication uses JSONL: one valid JSON object per line, no Markdown, no prose outside JSON.

## Roles

- Orchestrator: main agent. Owns the user goal, task graph, approved plan, acceptance criteria, final integration, and final response.
- Executor: owns implementation. May coordinate executor-side subagents for disjoint side tasks.
- Evaluator: owns acceptance criteria, evaluation plan, review, tests, and verification. May coordinate evaluator-side subagents for focused checks.
- Subagents: leaf agents owned by executor or evaluator.

## Envelope

Every line must follow this shape:

```json
{"schema_version":"harness-agent-jsonl/v1","message_type":"task_brief","from":"orchestrator","to":"executor","task_id":"task-001","parent_task_id":null,"phase":"intake","status":"open","seq":1,"payload":{}}
```

Required fields:

- `schema_version`: `harness-agent-jsonl/v1`
- `message_type`: protocol message type
- `from`: sender role or id
- `to`: recipient role or id
- `task_id`: stable task id
- `parent_task_id`: parent id or `null`
- `phase`: `intake`, `plan_sync`, `execution`, `evaluation`, `repair`, or `closeout`
- `status`: `open`, `proposed`, `approved`, `blocked`, `running`, `passed`, `failed`, or `complete`
- `seq`: sender-local monotonically increasing integer
- `payload`: message-specific object

## Message Types

- `task_brief`
- `implementation_plan`
- `acceptance_criteria`
- `acceptance_review`
- `approved_plan`
- `subtask_assignment`
- `subtask_result`
- `progress`
- `change_summary`
- `evaluation_result`
- `repair_request`
- `final_report`

## Required Sequence

1. Orchestrator sends `task_brief` to executor and evaluator.
2. Executor returns `implementation_plan`.
3. Evaluator returns `acceptance_criteria` and evaluation plan.
4. Executor and evaluator return `acceptance_review` for the plan/criteria.
5. Orchestrator resolves conflicts and sends `approved_plan`.
6. Executor implements, optionally assigning executor-side subtasks.
7. Executor returns `change_summary`.
8. Evaluator reviews/tests, optionally assigning evaluator-side subtasks.
9. Evaluator returns `evaluation_result`.
10. Orchestrator sends `repair_request` if needed, otherwise emits `final_report`.

## Examples

Executor plan:

```json
{"schema_version":"harness-agent-jsonl/v1","message_type":"implementation_plan","from":"executor","to":"orchestrator","task_id":"task-001","parent_task_id":null,"phase":"plan_sync","status":"proposed","seq":1,"payload":{"summary":"Add request validation and tests.","steps":["inspect boundary","add validator","add tests","run verification"],"write_scopes":["src/api","tests/api"],"subagents":[{"id":"executor-docs-001","purpose":"docs update","write_scope":["docs/harness"]}],"risks":["API compatibility"],"verification_commands":["npm test"]}}
```

Evaluator criteria:

```json
{"schema_version":"harness-agent-jsonl/v1","message_type":"acceptance_criteria","from":"evaluator","to":"orchestrator","task_id":"task-001","parent_task_id":null,"phase":"plan_sync","status":"proposed","seq":1,"payload":{"criteria":["invalid payload returns 400","valid payload behavior unchanged","tests cover both paths"],"evaluation_plan":["review diff","run npm test"],"blockers":[]}}
```
'@
}

function Get-QualityGates {
    param([string[]]$VerifyCommands)

    $verifyList = ($VerifyCommands | ForEach-Object { "- ``$_``" }) -join "`n"
    return @"
# Quality Gates

## Standard Commands

$verifyList
- ``powershell -ExecutionPolicy Bypass -File scripts/harness-check.ps1 -Mode audit``
- ``powershell -ExecutionPolicy Bypass -File scripts/harness-check.ps1 -Mode verify``

## Hard Gates For New Work

- No new hard-coded secrets, credentials, tokens, or production endpoint values.
- No automated tests that mutate live production systems.
- No unrelated generated/build/IDE metadata changes.
- No broad refactors hidden inside feature or bug tasks.
- Behavior changes must have tests or an explicit verification note.
- Security, auth, billing, migration, async, external API, and data-loss risks require RPI and usually an execution plan.

## Baseline Debt

Existing warnings belong in `docs/exec-plans/tech-debt-tracker.md`. Baseline debt is visible, but new work should not expand it.
"@
}

function Get-SubagentWorkflows {
    return @'
# Subagent Workflows

Use these workflows when the user explicitly asks for subagents or delegation. All child-agent output must be JSONL: one valid JSON object per line.

## Orchestrator

- Own the user goal, task graph, acceptance criteria, approved plan, final integration, and final answer.
- Send `task_brief` to executor and evaluator.
- Require executor `implementation_plan` and evaluator `acceptance_criteria` before coding starts.
- Resolve disagreements and emit `approved_plan`.
- Route `repair_request` back to executor if evaluator fails the change.
- Emit final user-facing summary only after evaluator returns `evaluation_result`.

## Executor

- Own implementation planning and code changes.
- Return `implementation_plan` before editing files.
- Coordinate executor-side subagents for disjoint side tasks when useful.
- Return `change_summary` with changed files, behavior, tests run, assumptions, and blockers.

## Evaluator

- Own acceptance criteria, evaluation plan, independent review, and test verification.
- Return `acceptance_criteria` before implementation starts.
- Review executor plan and return `acceptance_review`.
- Coordinate evaluator-side subagents for focused review, test, security, or regression checks.
- Return `evaluation_result` with verdict, findings, tests, and residual risk.

## Executor-Side Subagents

- Owned by executor.
- Implement bounded side tasks only.
- Return `subtask_result`.

## Evaluator-Side Subagents

- Owned by evaluator.
- Run focused review/check/test tasks only.
- Return `subtask_result`.

## Protocol

See `docs/harness/agent-protocol.md` and the `$harness-architect` skill reference `references/subagent-templates.md`.
'@
}

function Get-ExecPlansReadme {
    return @'
# Execution Plans

Use this directory for durable plans that should survive context windows.

- `active/`: plans currently being executed.
- `completed/`: completed plans and design history.
- `tech-debt-tracker.md`: recurring cleanup queue.

Small tasks can use an ephemeral conversation plan. Risky or long-running tasks should have a checked-in plan.
'@
}

function Get-TechDebt {
    return @'
# Technical Debt Tracker

Add items when repeated failures or known risks should be made visible but cannot be fixed immediately.

| Priority | Area | Finding | Preferred constraint | Status |
| --- | --- | --- | --- | --- |
| P0 | Harness | Initial scaffold needs project-specific refinement. | Fill project map, commands, boundaries, and known risks after codebase research. | Open |
'@
}

function Get-HarnessCheck {
    param([string[]]$VerifyCommands)

    $commandLiteral = ($VerifyCommands | ForEach-Object { "`"$_`"" }) -join ", "
    return @"
[CmdletBinding()]
param(
    [ValidateSet("audit", "verify")]
    [string]`$Mode = "audit"
)

`$ErrorActionPreference = "Stop"
`$Root = (Resolve-Path (Join-Path `$PSScriptRoot "..")).Path
`$issues = New-Object System.Collections.Generic.List[string]
`$warnings = New-Object System.Collections.Generic.List[string]

function Add-Issue { param([string]`$Message) `$issues.Add(`$Message) | Out-Null }
function Add-Warning { param([string]`$Message) `$warnings.Add(`$Message) | Out-Null }

`$required = @(
    "AGENTS.md",
    "ARCHITECTURE.md",
    "docs/harness/README.md",
    "docs/harness/agent-protocol.md",
    "docs/harness/quality-gates.md",
    "docs/harness/subagent-workflows.md",
    "docs/exec-plans/tech-debt-tracker.md"
)

foreach (`$path in `$required) {
    if (-not (Test-Path -LiteralPath (Join-Path `$Root `$path))) {
        Add-Issue "Missing harness doc: `$path"
    }
}

`$scanFiles = Get-ChildItem -LiteralPath `$Root -Recurse -File |
    Where-Object {
        `$_.FullName -notlike "*\.git\*" -and
        `$_.FullName -notlike "*\node_modules\*" -and
        `$_.FullName -notlike "*\target\*" -and
        `$_.FullName -notlike "*\dist\*" -and
        `$_.FullName -notlike "*\build\*" -and
        `$_.FullName -notlike "*\.idea\*" -and
        `$_.FullName -notlike "*\.venv\*"
    }

foreach (`$file in `$scanFiles) {
    `$relative = `$file.FullName.Substring(`$Root.Length + 1)
    if (`$file.Length -gt 500KB) {
        Add-Warning "Large tracked file candidate: `$relative"
    }
    if (`$file.Extension -in @(".java", ".js", ".ts", ".tsx", ".py", ".cs", ".go", ".rs", ".yml", ".yaml", ".properties", ".env")) {
        foreach (`$match in Select-String -LiteralPath `$file.FullName -Pattern '(?i)(api[_-]?key|secret|password|token)\s*[:=]\s*\S{8,}' -ErrorAction SilentlyContinue) {
            Add-Warning "Secret-like value: `${relative}:`$(`$match.LineNumber)"
        }
    }
}

if (`$Mode -eq "verify") {
    `$commands = @($commandLiteral)
    foreach (`$command in `$commands) {
        if (`$command -like "<fill*") {
            Add-Warning "Verification command not configured yet."
            continue
        }
        Write-Host "Running: `$command"
        Push-Location `$Root
        try {
            Invoke-Expression `$command
            if (`$LASTEXITCODE -ne 0) {
                Add-Issue "Command failed (`$LASTEXITCODE): `$command"
            }
        }
        finally {
            Pop-Location
        }
    }
}

if (`$warnings.Count -gt 0) {
    Write-Host ""
    Write-Host "Warnings:"
    foreach (`$warning in `$warnings) { Write-Host " - `$warning" }
}

if (`$issues.Count -gt 0) {
    Write-Host ""
    Write-Host "Issues:"
    foreach (`$issue in `$issues) { Write-Host " - `$issue" }
    exit 1
}

Write-Host ""
Write-Host "Harness check completed."
"@
}

function Invoke-Scaffold {
    param([string]$Root)

    $stack = Get-StackInfo -Root $Root
    Write-TextFile -Path (Join-Path $Root "AGENTS.md") -Content (Get-AgentsMd -Stack $stack.Stack -VerifyCommands $stack.VerifyCommands)
    Write-TextFile -Path (Join-Path $Root "ARCHITECTURE.md") -Content (Get-ArchitectureMd -Stack $stack.Stack)
    Write-TextFile -Path (Join-Path $Root "docs/harness/README.md") -Content (Get-HarnessReadme)
    Write-TextFile -Path (Join-Path $Root "docs/harness/agent-protocol.md") -Content (Get-AgentProtocol)
    Write-TextFile -Path (Join-Path $Root "docs/harness/quality-gates.md") -Content (Get-QualityGates -VerifyCommands $stack.VerifyCommands)
    Write-TextFile -Path (Join-Path $Root "docs/harness/subagent-workflows.md") -Content (Get-SubagentWorkflows)
    Write-TextFile -Path (Join-Path $Root "docs/exec-plans/README.md") -Content (Get-ExecPlansReadme)
    Write-TextFile -Path (Join-Path $Root "docs/exec-plans/tech-debt-tracker.md") -Content (Get-TechDebt)
    Write-TextFile -Path (Join-Path $Root "docs/exec-plans/active/.gitkeep") -Content ""
    Write-TextFile -Path (Join-Path $Root "docs/exec-plans/completed/.gitkeep") -Content ""
    Write-TextFile -Path (Join-Path $Root "scripts/harness-check.ps1") -Content (Get-HarnessCheck -VerifyCommands $stack.VerifyCommands)
}

function Invoke-DocsCheck {
    param([string]$Root)

    $required = @(
        "AGENTS.md",
        "ARCHITECTURE.md",
        "docs/harness/README.md",
        "docs/harness/agent-protocol.md",
        "docs/harness/quality-gates.md",
        "docs/harness/subagent-workflows.md",
        "docs/exec-plans/tech-debt-tracker.md",
        "scripts/harness-check.ps1"
    )
    $missing = @()
    foreach ($path in $required) {
        if (-not (Test-Path -LiteralPath (Join-Path $Root $path))) {
            $missing += $path
        }
    }
    if ($missing.Count -gt 0) {
        Write-Host "Missing harness files:"
        foreach ($path in $missing) { Write-Host " - $path" }
        exit 1
    }
    Write-Host "All required harness files exist."
}

function Invoke-Audit {
    param([string]$Root)

    Invoke-DocsCheck -Root $Root
    $check = Join-Path $Root "scripts/harness-check.ps1"
    & powershell -ExecutionPolicy Bypass -File $check -Mode audit
    exit $LASTEXITCODE
}

if ($Command -eq "commands") {
    Show-Commands
    exit 0
}

$root = Resolve-RepoRoot -Path $RepoPath

if ($Command -eq "scaffold") {
    Invoke-Scaffold -Root $root
    exit 0
}

if ($Command -eq "docs-check") {
    Invoke-DocsCheck -Root $root
    exit 0
}

if ($Command -eq "audit") {
    Invoke-Audit -Root $root
    exit 0
}
