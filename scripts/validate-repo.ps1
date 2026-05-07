[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$issues = New-Object System.Collections.Generic.List[string]

function Add-Issue {
    param([string]$Message)
    $issues.Add($Message) | Out-Null
}

$required = @(
    "README.md",
    "LICENSE",
    "AGENTS.md",
    "CONTRIBUTING.md",
    "SECURITY.md",
    "docs/agent-jsonl-protocol.md",
    "docs/inspirations.md",
    "skills/harness-architect/SKILL.md",
    "skills/harness-architect/scripts/harness-architect.ps1",
    "skills/harness-architect/scripts/harness-architect.sh"
)

foreach ($path in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $Root $path))) {
        Add-Issue "Missing required file: $path"
    }
}

$skill = Get-Content -LiteralPath (Join-Path $Root "skills/harness-architect/SKILL.md") -Raw
if ($skill -notmatch "name:\s*harness-architect") {
    Add-Issue "Skill frontmatter is missing name: harness-architect"
}
if ($skill -notmatch "JSONL") {
    Add-Issue "Skill should describe the JSONL inter-agent protocol"
}

$protocol = Get-Content -LiteralPath (Join-Path $Root "docs/agent-jsonl-protocol.md") -Raw
foreach ($term in @("orchestrator", "executor", "evaluator", "harness-agent-jsonl/v1")) {
    if ($protocol -notmatch [regex]::Escape($term)) {
        Add-Issue "Protocol doc missing required term: $term"
    }
}

Push-Location $Root
try {
    & powershell -ExecutionPolicy Bypass -File "skills/harness-architect/scripts/harness-architect.ps1" -Command commands | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Add-Issue "Harness Architect command script failed"
    }
}
finally {
    Pop-Location
}

if ($issues.Count -gt 0) {
    Write-Host "Validation failed:"
    foreach ($issue in $issues) {
        Write-Host " - $issue"
    }
    exit 1
}

Write-Host "Repository validation passed."
